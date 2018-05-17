defmodule ExDDNS.Services.Cloudflare do
  @moduledoc """
  Interface to Cloudflare. Provides an API with everything necessary to
  update dns record.
  """

  use Tesla

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
  @spec list_dns_records(Client.t()) :: {:ok, [map]} | {:error, any}
  def list_dns_records(%Client{} = client) do
    case get(client, "/dns_records") do
      {:ok, %Env{status: 200, body: body}} ->
        Map.fetch(body, "result")

      {:ok, %Env{body: body}} ->
        {:error, extract_error(body)}

      error ->
        error
    end
  end

  @doc """
  Updates an dns record.
  """
  @spec update_dns_record(Client.t(), String.t(), dns_record_params) ::
          :ok | {:error, any}
  def update_dns_record(client, dns_record_id, dns_record_params)
      when is_binary(dns_record_id) and is_map(dns_record_params) do
    case put(client, "/dns_records/#{dns_record_id}", dns_record_params) do
      {:ok, %Env{status: 200}} -> :ok
      {:ok, %Env{body: body}} -> {:error, extract_error(body)}
      error -> error
    end
  end

  @doc """
  Builds a `Telsa.Client`.

  Plugs middlewares to set the `base_url`, the auth headers and handle
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

  defp extract_error(%{"errors" => [error | _]}) do
    case Map.fetch(error, "message") do
      {:ok, message} -> message
      :error -> "Unexpected error"
    end
  end
end
