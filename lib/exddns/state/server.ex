defmodule ExDDNS.State.Server do
  use GenServer
  require Logger
  alias State

  defmodule State do
    @enforce_keys ~w(update_dns_fun fetch_ip_fun timeout)a
    defstruct ~w(
      current_ip
      fetch_ip_fun
      last_check
      last_update
      name
      timeout
      update_dns_fun
    )a
  end

  def start_link(opts) do
    case init_state(opts) do
      %State{name: nil} = state ->
        GenServer.start_link(__MODULE__, state)

      %State{name: name} = state ->
        GenServer.start_link(__MODULE__, state, name: name)
    end
  end

  defp init_state(%State{} = state), do: state
  defp init_state(opts), do: struct!(State, opts)

  def init(state) do
    send(self(), :update_current_ip)
    {:ok, state}
  end

  def get_state(pid \\ __MODULE__), do: GenServer.call(pid, :get_state)

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_info(:update_current_ip, state) do
    new_state = maybe_update_current_ip(state)
    Process.send_after(self(), :update_current_ip, state.timeout)
    {:noreply, new_state}
  end

  defp maybe_update_current_ip(state) do
    with {:ok, fetched_ip} <- apply(state.fetch_ip_fun, []),
         true <- update_current_ip?(state.current_ip, fetched_ip),
         :ok <- apply(state.update_dns_fun, []) do
      Logger.info "Updated DNS record, new IP is: #{fetched_ip}"
      %{state | current_ip: fetched_ip}
      |> update_last_check
      |> update_last_update
    else
      false ->
        Logger.info("IP is still the same. Doing nothing...")
        state |> update_last_check
      error ->
        Logger.error("Failed to update current ip: #{inspect(error)}")
        state
    end
  end

  defp update_current_ip?(ip, ip), do: false
  defp update_current_ip?(_, _), do: true

  defp update_last_check(state), do: %{state | last_check: DateTime.utc_now()}

  defp update_last_update(state), do: %{state | last_update: DateTime.utc_now()}
end
