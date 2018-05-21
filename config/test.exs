use Mix.Config

config :ex_ddns, :env, :test

config :tesla, adapter: Tesla.Mock
