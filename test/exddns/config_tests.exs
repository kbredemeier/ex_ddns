defmodule ExDDNS.ConfigTest do
  use ExUnit.Case, async: false

  alias ExDDNS.Config

  @mix_config [
    update_timeout: 1000,
    service: ExDDNS.Services.Cloudflare
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

    test "update_timeout", %{config: config} do
      assert config.update_timeout == @mix_config[:update_timeout]
    end

    test "service", %{config: config} do
      assert config.service == @mix_config[:service]
    end
  end

  describe "init/0 reads values from env" do
    setup do
      current_config = Application.get_env(:exddns, Config)
      Application.put_env(:exddns, Config, [])

      on_exit(fn ->
        Application.put_env(:exddns, Config, current_config)
      end)

      System.put_env("EXDDNS_DOMAIN", "aaa")
      System.put_env("EXDDNS_UPDATE_TIMEOUT", "9999")
      System.put_env("EXDDNS_SERVICE", "Cloudflare")

      {:ok, config: Config.init()}
    end

    test "update_timeout", %{config: config} do
      assert config.update_timeout == 9999
    end

    test "service", %{config: config} do
      assert config.service == ExDDNS.Services.Cloudflare
    end
  end

  describe "init/0 value casting" do
    setup do
      current_config = Application.get_env(:exddns, Config)
      Application.put_env(:exddns, Config, [])

      on_exit(fn ->
        Application.put_env(:exddns, Config, current_config)
      end)

      System.put_env("EXDDNS_DOMAIN", "aaa")
      System.put_env("EXDDNS_UPDATE_TIMEOUT", "9999")
      System.put_env("EXDDNS_SERVICE", "Cloudflare")

      :ok
    end

    test "update_timeout" do
      System.put_env("EXDDNS_UPDATE_TIMEOUT", "fooo")
      assert_raise RuntimeError, &Config.init/0
    end

    test "service" do
      System.put_env("EXDDNS_SERVICE", "fooo")
      assert_raise RuntimeError, &Config.init/0
    end
  end

  test "init/0 raises an error if any value is missing" do
    current_config = Application.get_env(:exddns, Config)
    Application.put_env(:exddns, Config, [])

    on_exit(fn ->
      Application.put_env(:exddns, Config, current_config)
    end)

    System.put_env("EXDDNS_DOMAIN", "")
    System.put_env("EXDDNS_UPDATE_TIMEOUT", "")
    System.put_env("EXDDNS_SERVICE", "")

    assert_raise RuntimeError, &Config.init/0
  end
end
