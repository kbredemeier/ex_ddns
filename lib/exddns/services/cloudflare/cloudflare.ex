defmodule ExDDNS.Services.Cloudflare do
  @moduledoc """
  Interface to Cloudflare. Provides an API with everything necessary to
  update dns record.
  """

  use Tesla

  require Logger

  alias ExDDNS.Services.Cloudflare.Config
  alias Tesla.Env
  alias Tesla.Client
  alias Tesla.Middleware.BaseUrl
  alias Tesla.Middleware.Headers
  alias Tesla.Middleware.JSON

  @typedoc """
  Params to update a dns record with the Cloudflare API.

  ## Attributes

  * `type` The type of the record, for example `A`.
  * `name` The domain name, for example `example.com`.
  * `content` The ip address the record should point to.
  """
  @type dns_record_params :: %{
          type: String.t(),
          name: String.t(),
          content: String.t()
        }

  @doc """
  Lists all dns records. Can be usefull to find out the ID of your record.

  For details see [here](https://api.cloudflare.com/#dns-records-for-a-zone-list-dns-records)
  """
  @spec list_dns_records(Client.t()) ::
          {:ok, [map]} | {:error, :list_dns_records_faild}
  def list_dns_records(%Client{} = client) do
    case get(client, "/dns_records") do
      {:ok, %Env{status: 200, body: body}} ->
        Map.fetch(body, "result")

      {:ok, %Env{body: body}} ->
        body
        |> get_errors_from_body
        |> log_list_dns_records_failed

        {:error, :list_dns_records_failed}

      {:error, reason} ->
        log_list_dns_records_failed(reason)
        {:error, :list_dns_records_failed}
    end
  end

  defp log_list_dns_records_failed(reason) do
    Logger.error(
      "Failed to fetch dns records from Cloudflare API: #{inspect(reason)}"
    )
  end

  @doc """
  Updates a dns record with the Cloudflare API.
  """
  @spec update_dns_record(Client.t(), String.t(), dns_record_params) ::
          :ok | {:error, :update_dns_record_failed}
  def update_dns_record(client, dns_record_id, dns_record_params)
      when is_binary(dns_record_id) and is_map(dns_record_params) do
    case put(client, "/dns_records/#{dns_record_id}", dns_record_params) do
      {:ok, %Env{status: 200, body: body}} ->
        log_dns_update_success(body)
        :ok

      {:ok, %Env{body: body}} ->
        body
        |> get_errors_from_body()
        |> log_update_dns_failed()

        {:error, :update_dns_record_failed}

      {:error, reason} ->
        log_update_dns_failed(reason)
        {:error, :update_dns_record_failed}
    end
  end

  defp log_dns_update_success(body) do
    new_ip = get_in(body, ~w(result content))
    name = get_in(body, ~w(result name))

    Logger.info(
      "Updated dns record with Cloudflare API: The new IP address for #{
        inspect(name)
      } is #{inspect(new_ip)}"
    )
  end

  defp log_update_dns_failed(reason) do
    Logger.error(
      "Failed to update dns record on Cloudflare API: #{inspect(reason)}"
    )
  end

  @doc """
  Builds a `Telsa.Client` for using the Cloudflare API.
  """
  @spec client(Config.t()) :: Tesla.Client.t()
  def client(%Config{x_auth_email: email, x_auth_key: key, zone_id: zone_id}) do
    Tesla.build_client([
      {BaseUrl, "https://api.cloudflare.com/client/v4/zones/#{zone_id}"},
      {Headers, [{"x-auth-email", email}, {"x-auth-key", key}]},
      {JSON, []}
    ])
  end

  @doc """
  Builds a #{Config},
  """
  @spec config :: Config.t()
  def config do
    Config.init()
  end

  def get_errors_from_body(%{"errors" => errors}),
    do: do_fetch_errors(errors, [])

  def get_errors_from_body(_), do: []

  defp do_fetch_errors([], agg), do: agg

  defp do_fetch_errors([head | tail], agg) do
    new_agg = fetch_messages(head, agg)
    do_fetch_errors(tail, new_agg)
  end

  defp fetch_messages(%{"message" => msg, "error_chain" => errors}, agg) do
    [{msg, do_fetch_errors(errors, [])} | agg]
  end

  defp fetch_messages(%{"message" => msg}, agg), do: [{msg, []} | agg]
end
