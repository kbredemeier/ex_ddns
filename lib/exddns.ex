defmodule ExDDNS do
  @moduledoc """
  Documentation for ExDDNS.
  """

  alias ExDDNS.Config
  alias ExDDNS.State.CurrentIp

  @doc """
  Buils options for the `ExDDNS.State.Server` based on confiured values.
  """
  @spec init_opts :: keyword
  def init_opts do
    config = Config.init()

    [
      timeout: config.update_timeout,
      fetch_ip_fun: &CurrentIp.fetch/0,
      update_dns_fun: &update_dns_record/0
    ]
  end

  defp update_dns_record, do: :ok
end
