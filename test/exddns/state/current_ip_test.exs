defmodule ExDDNS.State.CurrentIpTest do
  use ExUnit.Case, async: true

  import Tesla.Mock

  alias ExDDNS.State.CurrentIp
  alias Tesla.Env

  describe "fetch/0" do
    test "status 200 returns an ok tuple with the ip" do
      mock(fn %{method: :get, url: "https://canihazip.com/s"} ->
        %Env{status: 200, body: "192.168.1.100"}
      end)

      assert {:ok, "192.168.1.100"} = CurrentIp.fetch()
    end

    test "any other status retuns an error tuple with the status code" do
      mock(fn %{method: :get, url: "https://canihazip.com/s"} ->
        %Env{status: 444}
      end)

      assert {:error, 444} == CurrentIp.fetch()
    end
  end
end
