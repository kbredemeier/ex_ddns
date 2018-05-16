defmodule ExDDNS.ConfigTest do
  use ExUnit.Case, async: false

  alias ExDDNS.Config

  @mix_config [
    domain: "example.com"
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

    test "domain", %{config: config} do
      assert config.domain == @mix_config[:domain]
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

      {:ok, config: Config.init()}
    end

    test "domain", %{config: config} do
      assert config.domain == "aaa"
    end
  end

  test "init/0 raises an error if any value is missing" do
    current_config = Application.get_env(:exddns, Config)
    Application.put_env(:exddns, Config, [])

    on_exit(fn ->
      Application.put_env(:exddns, Config, current_config)
    end)

    System.put_env("EXDDNS_DOMAIN", "")

    assert_raise RuntimeError, &Config.init/0
  end
end
