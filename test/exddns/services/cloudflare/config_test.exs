defmodule ExDDNS.Services.Cloudflare.ConfigTest do
  use ExUnit.Case, async: false

  alias ExDDNS.Services.Cloudflare.Config

  @mix_config [
    x_auth_email: "user@example.com",
    x_auth_key: "super secret key",
    zone_id: "asd-qwe-zxc-dfg-rty",
    dns_record_id: "vnw-doq-sdn-asd-bgr"
  ]

  describe "init/0 reads values from mix config" do
    setup do
      current_config = Application.get_env(:exddns, Config)

      on_exit(fn ->
        Application.put_env(:exddns, Config, current_config)
      end)

      Application.put_env(:exddns, Config, @mix_config)
      {:ok, config: Config.init()}
    end

    test "x_auth_email", %{config: config} do
      assert config.x_auth_email == @mix_config[:x_auth_email]
    end

    test "x_auth_key", %{config: config} do
      assert config.x_auth_key == @mix_config[:x_auth_key]
    end

    test "zone_id", %{config: config} do
      assert config.zone_id == @mix_config[:zone_id]
    end

    test "domain", %{config: config} do
      assert config.domain == @mix_config[:domain]
    end

    test "dns_record_id", %{config: config} do
      assert config.dns_record_id == @mix_config[:dns_record_id]
    end
  end

  describe "init/0 reads values from env" do
    setup do
      current_config = Application.get_env(:exddns, Config)
      Application.put_env(:exddns, Config, [])

      on_exit(fn ->
        Application.put_env(:exddns, Config, current_config)
      end)

      System.put_env("CLOUDFLARE_X_AUTH_EMAIL", "aaa")
      System.put_env("CLOUDFLARE_X_AUTH_KEY", "bbb")
      System.put_env("CLOUDFLARE_ZONE_ID", "ccc")
      System.put_env("CLOUDFLARE_DOMAIN", "ddd")
      System.put_env("CLOUDFLARE_DNS_RECORD_ID", "eee")

      {:ok, config: Config.init()}
    end

    test "x_auth_email", %{config: config} do
      assert config.x_auth_email == "aaa"
    end

    test "x_auth_key", %{config: config} do
      assert config.x_auth_key == "bbb"
    end

    test "zone_id", %{config: config} do
      assert config.zone_id == "ccc"
    end

    test "domain", %{config: config} do
      assert config.domain == "ddd"
    end

    test "dns_record_id", %{config: config} do
      assert config.dns_record_id == "eee"
    end
  end

  test "init/0 raises an error if any value is missing" do
    current_config = Application.get_env(:exddns, Config)
    Application.put_env(:exddns, Config, [])

    on_exit(fn ->
      Application.put_env(:exddns, Config, current_config)
    end)

    System.put_env("CLOUDFLARE_X_AUTH_EMAIL", "")
    System.put_env("CLOUDFLARE_X_AUTH_KEY", "")
    System.put_env("CLOUDFLARE_ZONE_ID", "")
    System.put_env("CLOUDFLARE_DOMAIN", "")
    System.put_env("CLOUDFLARE_DNS_RECORD_ID", "")

    assert_raise RuntimeError, &Config.init/0
  end

  describe "init/0 raises an error for missing config values casting" do
    setup do
      current_config = Application.get_env(:exddns, Config)
      Application.put_env(:exddns, Config, [])

      on_exit(fn ->
        Application.put_env(:exddns, Config, current_config)
      end)

      System.put_env("CLOUDFLARE_X_AUTH_EMAIL", "aaa")
      System.put_env("CLOUDFLARE_X_AUTH_KEY", "bbb")
      System.put_env("CLOUDFLARE_ZONE_ID", "ccc")
      System.put_env("CLOUDFLARE_DOMAIN", "ddd")
      System.put_env("CLOUDFLARE_DNS_RECORD_ID", "eee")

      assert Config.init

      :ok
    end

    test "x_auth_email" do
      System.put_env("CLOUDFLARE_X_AUTH_EMAIL", "")
      assert_raise RuntimeError, ~r/x_auth_email/, &Config.init/0
      System.put_env("CLOUDFLARE_X_AUTH_EMAIL", "aaa")
    end

    test "x_auth_key" do
      System.put_env("CLOUDFLARE_X_AUTH_KEY", "")
      assert_raise RuntimeError, ~r/x_auth_key/, &Config.init/0
      System.put_env("CLOUDFLARE_X_AUTH_KEY", "bbb")
    end

    test "zone_id" do
      System.put_env("CLOUDFLARE_ZONE_ID", "")
      assert_raise RuntimeError, ~r/zone_id/, &Config.init/0
      System.put_env("CLOUDFLARE_ZONE_ID", "bbb")
    end

    test "domain" do
      System.put_env("CLOUDFLARE_DOMAIN", "")
      assert_raise RuntimeError, ~r/domain/, &Config.init/0
      System.put_env("CLOUDFLARE_DOMAIN", "bbb")
    end

    test "dns_record_id" do
      System.put_env("CLOUDFLARE_DNS_RECORD_ID", "")
      assert_raise RuntimeError, ~r/dns_record_id/, &Config.init/0
      System.put_env("CLOUDFLARE_DNS_RECORD_ID", "bbb")
    end
  end
end
