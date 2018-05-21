defmodule ExDDNS.Config do
  @moduledoc """
  Configuration for ExDDNS.

  You can configure ExDDNS by adding the required configuration
  to your mix config:

      # config/config.exs
      use Mix.Config

      config :ex_ddns, #{__MODULE__},
        update_timeout: 15*60*1000,
        service: ExDDNS.Services.Cloudflare


  Or you can set the variables in your environment:

  export EX_DDNS_DOMAIN=user@example.com
  export EX_DDNS_UPDATE_TIMEOUT=900000
  export EX_DDNS_SERVICE=Cloudflare

  The value for EX_DDNS_SERVICE matches the name of the desired module without
  the whole namespace.
  """

  @enforce_keys ~w(update_timeout service)a
  defstruct ~w(update_timeout service)a

  @typedoc """
  Specifiels all common config values for `ExDDS`.

  ## Attributes

  * `update_timeout` Sets the timeout in ms for the dns record update
  * `service` Sets the service module which handles the API calls to the
    dns service.
  """
  @type t :: %__MODULE__{
          service: module,
          update_timeout: number
        }

  @doc """
  Initializes a config. It tries to read the values from the mix config and
  falls back to environment variables.
  """
  @spec init :: __MODULE__.t()
  def init do
    %__MODULE__{
      update_timeout: get_config_value(:update_timeout),
      service: get_config_value(:service)
    }
  end

  defp get_config_value(key) do
    :ex_ddns
    |> Application.get_env(__MODULE__)
    |> Kernel.||([])
    |> Keyword.get_lazy(key, fn -> fetch_from_env(key) end)
    |> cast_value(key)
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
    "EX_DDNS_#{key |> Atom.to_string() |> String.upcase()}"
  end

  defp cast_value(value, :update_timeout) when is_binary(value) do
    case Integer.parse(value) do
      {timeout, _} -> timeout
      :error -> raise_cast_error(:update_timeout, value)
    end
  end

  defp cast_value(value, :service) when is_binary(value) do
    String.to_existing_atom("Elixir.ExDDNS.Services.#{value}")
  rescue
    ArgumentError -> raise_cast_error(:service, value)
  end

  defp cast_value(value, _), do: value

  defp raise_cast_error(key, value) do
    """
    Failed to cast #{key} in #{__MODULE__}.

    You have set a invalid value for `:#{key}`: #{value}. Check in your mix
    config the value for  #{key} or make sure your environment has a valid value
    for #{to_env_var(key)}.
    """
    |> String.trim()
    |> raise
  end
end
