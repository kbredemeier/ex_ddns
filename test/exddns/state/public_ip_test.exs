defmodule ExDDNS.State.PublicIpTest do
  use ExUnit.Case, async: true

  import Tesla.Mock
  import ExUnit.CaptureLog

  alias ExDDNS.State.PublicIp
  alias Tesla.Env

  describe "fetch/0" do
    test "status 200 returns an ok tuple with the ip" do
      mock(fn %{method: :get, url: "https://canihazip.com/s"} ->
        %Env{status: 200, body: "192.168.1.100"}
      end)

      assert {:ok, "192.168.1.100"} = PublicIp.fetch()
    end

    test "any other status retuns an error tuple" do
      mock(fn %{method: :get, url: "https://canihazip.com/s"} ->
        %Env{status: 444}
      end)

      assert {:error, :fetch_failed} == PublicIp.fetch()
    end

    test "It logs the fetched ip address" do
      mock(fn %{method: :get, url: "https://canihazip.com/s"} ->
        %Env{status: 200, body: "127.0.0.1"}
      end)

      log = capture_log(&PublicIp.fetch/0)
      assert log =~ "Fetched public IP address: \"127.0.0.1\""
    end

    test "It logs if response has wrong status code" do
      mock(fn %{method: :get, url: "https://canihazip.com/s"} ->
        %Env{status: 444}
      end)

      log = capture_log(&PublicIp.fetch/0)
      assert log =~ "Failed to fetch current IP address. Status: \"444\""
    end

    test "It logs if response does not contain a valid ipv4 address" do
      mock(fn %{method: :get, url: "https://canihazip.com/s"} ->
        %Env{status: 200, body: "192.168.1.100.123"}
      end)

      log = capture_log(&PublicIp.fetch/0)

      assert log =~
               "Response contains invalid IPv4 address: \"192.168.1.100.123\""
    end

    test "It logs if fatal errors" do
      mock(fn %{method: :get, url: "https://canihazip.com/s"} ->
        {:error, :econnrefused}
      end)

      log = capture_log(&PublicIp.fetch/0)
      assert log =~ "Fatal error while trying to fetch"
      assert log =~ "econnrefused"
    end
  end
end
