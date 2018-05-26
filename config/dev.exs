use Mix.Config

config :ex_ddns, ExDDNS.Services.Cloudflare.Config,
  x_auth_email: "k.bredemeier@gmail.com",
  x_auth_key: "a157f8a6ce16143d48b235512d3bf76880017",
  zone_id: "5a4e3be3ca6d0b884ce968eca5ea0eef",
  domain: "holisticdev.io",
  dns_record_id: "dc21ee8ee8366e682d1ddedc3f1216f1"

config :ex_ddns, :env, :dev
