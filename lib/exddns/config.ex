defmodule ExDDNS.Config do
  @moduledoc """
  Configuration for ExDDNS.

  You can configure the ExDDNS by adding the required configuration
  to your mix config:

      # config/config.exs
      use Mix.Config

      config :exddns, #{__MODULE__},
        domain: "example.com",


  Or you can set the variables in your environment:

  export EXDDNS_DOMAIN=user@example.com
  """

  @enforce_keys ~w(domain)a
  defstruct ~w(domain)a

  @typedoc """
  Specifiels all common config values for `ExDDS`.

  ## Attributes

  * `domain` Specifies the default domain for which dns record operations are
    performed.
  """
  @type t :: %__MODULE__{
          domain: String.t()
        }

  @doc """
  Initializes a config. It tries to read the values from the mix config and
  falls back to environment variables.
  """
  @spec init :: __MODULE__.t()
  def init do
    %__MODULE__{
      domain: get_config_value(:domain)
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
    "EXDDNS_#{key |> Atom.to_string() |> String.upcase()}"
  end
end
