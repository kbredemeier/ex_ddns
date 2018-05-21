defmodule ExDDNS.State.Server do
  @moduledoc """
  This `GenServer` has several responsibilities:

  * it memoizes a  IP address. Probably the public IP address of the machine
    that uses this server.
  * it periodicly checks the current IP
  * updates a dns record if the public IP addres changes.
  """

  use GenServer

  require Logger

  alias State

  defmodule State do
    @moduledoc """
    Defines the internal state for `ExDDNS.State.Server`.
    """

    @typedoc """
    The internal state of the server

    ## Attributes

    * `:ip_address` The IP address the dns record will point to.
    * `:fetch_ip_fun` A function that returns the an IP address.
    * `:last_check` A `DateTime` from the last time the IP has been checked
      successfully.
    * `:last_update` A `DateTime` from the last time the dns record has been
      updated successfully.
    * `:name` The name the server process is registred with.
    * `:update_dns_fun` A function that takes a IP address as argument and
      updates a dns record.
    """
    @type t :: %__MODULE__{
            ip_address: String.t(),
            fetch_ip_fun: (() -> {:ok, String.t()} | {:error, :fetch_failed}),
            last_check: DateTime.t(),
            last_update: DateTime.t(),
            name: atom | pid,
            timeout: number,
            update_dns_fun:
              (String.t() -> :ok | {:error, :update_dns_record_failed})
          }
    @enforce_keys ~w(update_dns_fun fetch_ip_fun timeout)a
    defstruct ~w(
      ip_address
      fetch_ip_fun
      last_check
      last_update
      name
      state
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
    send(self(), :update_ip_address)
    {:ok, state}
  end

  def get_state(pid \\ __MODULE__), do: GenServer.call(pid, :get_state)

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_info(:update_ip_address, state) do
    new_state = maybe_update_ip_address(state)
    Process.send_after(self(), :update_ip_address, state.timeout)
    {:noreply, new_state}
  end

  defp maybe_update_ip_address(state) do
    with {:ok, fetched_ip} <- apply(state.fetch_ip_fun, []),
         true <- update_ip_address?(state.ip_address, fetched_ip),
         :ok <- apply(state.update_dns_fun, [fetched_ip]) do
      %{state | ip_address: fetched_ip}
      |> update_last_check
      |> update_last_update
    else
      false ->
        log_no_need_for_update()
        state |> update_last_check

      {:error, :fetch_failed} ->
        state

      {:error, :update_dns_record_failed} ->
        state |> update_last_check
    end
  end

  defp log_no_need_for_update do
    Logger.info(
      "Public IP address did not change. No need to update the dns record."
    )
  end

  defp update_ip_address?(ip, ip), do: false

  defp update_ip_address?(_, _), do: true

  defp update_last_check(state), do: %{state | last_check: DateTime.utc_now()}

  defp update_last_update(state), do: %{state | last_update: DateTime.utc_now()}
end
