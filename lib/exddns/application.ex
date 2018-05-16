defmodule ExDDNS.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias ExDDNS
  alias ExDDNS.State.Server

  def start(_type, _args) do
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ExDDNS.Supervisor]

    :exddns
    |> Application.get_env(:env)
    |> children
    |> Supervisor.start_link(opts)
  end

  def children(:test), do: []

  def children(_) do
    import Supervisor.Spec

    server_opts = ExDDNS.init_opts()

    [worker(Server, [server_opts])]
  end
end
