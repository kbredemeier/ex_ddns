defmodule ExDDNS.State.PublicIp do
  @moduledoc """
  This module is responsible for retrieving the public ip address.of the client.

  I uses [canihazip.com](https://canihazip.com) to do so.
  """
  use Tesla

  require Logger

  alias Tesla.Env

  @typedoc """
  The result of the `fetch/0` function. Is either `{:ok, ip_string}` or
  {:error, :fetch_failed}`
  """
  @type result :: {:ok, String.t()} | {:error, :fetch_failed}

  plug(Tesla.Middleware.BaseUrl, "https://canihazip.com")

  @doc """
  Fetches the public IP address.
  """
  @spec fetch :: result
  def fetch do
    case get("/s") do
      {:ok, %Env{status: 200, body: ip} = env} ->
        if Regex.match?(~r/^(\d{1,3}\.){3}\d{1,3}$/, ip) do
          log_fetch_success(ip)
          {:ok, ip}
        else
          log_invalid_ip(env)
          {:error, :fetch_failed}
        end

      {:ok, %Env{} = env} ->
        log_fetch_error(env)
        {:error, :fetch_failed}

      {:error, reason} ->
        log_fatal_error(reason)
        {:error, :fetch_faild}
    end
  end

  defp log_fetch_success(ip) do
    Logger.info("Fetched public IP address: #{inspect(ip)}")
  end

  defp log_invalid_ip(%{body: body}) do
    Logger.error("Response contains invalid IPv4 address: #{inspect(body)}")
  end

  defp log_fetch_error(%{status: status, body: body}) do
    Logger.error(
      "Failed to fetch current IP address. Status: \"#{status}\". Body:" <>
        " #{inspect(body)}"
    )
  end

  defp log_fatal_error(reason) do
    Logger.error(
      "Fatal error while trying to fetch the current ip address" <>
        " #{inspect(reason)}. There is probably something wrong with thr uri."
    )
  end
end
