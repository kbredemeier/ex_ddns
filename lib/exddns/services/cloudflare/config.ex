defmodule ExDDNS.Services.Cloudflare.Config do
  @moduledoc """
  Configuration for Cloudflare service.

  You can configure the Cloudflare service by adding the required configuration
  to your mix config:

      # config/config.exs
      use Mix.Config

      config :exddns, #{__MODULE__},
        x_auth_email: "user@example.com",
        x_auth_key: "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
        zone_id: "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"


  Or you can set the variables in your environment:

  export CLOUDFLARE_X_AUTH_EMAIL=user@example.com
  export CLOUDFLARE_X_AUTH_KET=xxx
  export CLOUDFLARE_ZONE_ID=xxx
  """

  @enforce_keys ~w(x_auth_email x_auth_key zone_id)a
  defstruct ~w(x_auth_email x_auth_key zone_id)a

  @typedoc """
  Specifies all values required to use the Cloudflare `dns_records` API
  endpoint.

  ## Attributes

  * `x_auth_email` Specifies the value for the `X_AUTH_EMAIL` header.
  * `x_auth_key` Specifies the value for the `X_AUTH_KEY` header.
  * `zone_id` Specifies the Cloudflare zone id for the requests.
  """
  @type t :: %__MODULE__{
          x_auth_email: String.t(),
          x_auth_key: String.t(),
          zone_id: String.t()
        }

  @doc """
  Initializes a config. It tries to read the values from the mix config and
  falls back to environment variables.
  """
  @spec init :: __MODULE__.t()
  def init do
    %__MODULE__{
      x_auth_email: get_config_value(:x_auth_email),
      x_auth_key: get_config_value(:x_auth_key),
      zone_id: get_config_value(:zone_id)
    }
  end

  defp get_config_value(key) do
    :exddns
    |> Application.get_env(__MODULE__)
    |> Kernel.||([])
    |> Keyword.get_lazy(key, fn -> fetch_from_env(key) end)
  end

  defp fetch_from_env(key) do
    key
    |> to_env_var
    |> System.get_env()
    |> case do
      nil -> raise_init_config_error(key)
      "" -> raise_init_config_error(key)
      value -> value
    end
  end

  defp raise_init_config_error(key) do
    """
    Failed to initialize the config for #{__MODULE__}.

    You did not set any value for `:#{key}`. To do so add #{key} to your mix
    config or set #{to_env_var(key)} in your environment.
    """
    |> String.trim()
    |> raise
  end

  defp to_env_var(key) do
    "CLOUDFLARE_#{key |> Atom.to_string() |> String.upcase()}"
  end
end
