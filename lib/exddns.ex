defmodule ExDDNS do
  @moduledoc """
  Documentation for ExDDNS.
  """

  alias ExDDNS.Config
  alias ExDDNS.State.PublicIp

  @doc """
  Buils options for the `ExDDNS.State.Server` based on confiured values.
  """
  @spec init_opts :: keyword
  def init_opts do
    config = Config.init()

    update_dns_record_fun =
      config.service
      |> get_service_mod
      |> build_update_dns_record_fun

    [
      timeout: config.update_timeout,
      fetch_ip_fun: &PublicIp.fetch/0,
      update_dns_fun: update_dns_record_fun
    ]
  end

  defp build_update_dns_record_fun(service_mod) do
    service_config = apply(service_mod, :config, [])
    service_api_client = apply(service_mod, :client, [service_config])

    fn ip_address ->
      opts = [
        service_api_client,
        service_config.dns_record_id,
        %{
          name: service_config.domain,
          type: "A",
          content: ip_address
        }
      ]

      apply(service_mod, :update_dns_record, opts)
    end
  end

  defp get_service_mod(name) when is_binary(name) do
    "ExDDNS.Services.#{name}"
    |> String.to_existing_atom()
    |> get_service_mod
  end

  defp get_service_mod(mod) do
    if Code.ensure_compiled?(mod) do
      mod
    else
      raise "Unknown service module: #{mod}"
    end
  end
end
