defmodule ExDDNS.State.ServerTest do
  use ExUnit.Case

  alias ExDDNS.State.Server

  @update_timeout 1000

  test "start_link with valid opts" do
    {:ok, pid} =
      Server.start_link(
        fetch_ip_fun: fetch_ip(),
        update_dns_fun: update_dns_record(),
        timeout: @update_timeout
      )
    assert state = Server.get_state(pid)
    assert state.ip_address == "10.10.10.10"
    assert %DateTime{} = state.last_update
    assert %DateTime{} = state.last_check
  end

  describe "updating dns records" do
    setup do
      {:ok, pid} =
        Server.start_link(
          fetch_ip_fun: fetch_ip(),
          update_dns_fun: update_dns_record(),
          timeout: @update_timeout
        )

      {:ok, server: pid}
    end

    test "invokes the fetch_ip/0 fun" do
      assert_receive :fetch_ip_invoked
    end

    test "it invokes the fetch ip fun again within the timeout" do
      assert_receive :fetch_ip_invoked
      refute_receive :fetch_ip_invoked, @update_timeout - 10
      assert_receive :fetch_ip_invoked
    end

    test "it invokes the update_dns_fun once" do
      assert_receive :fetch_ip_invoked
      assert_receive {:update_dns_record_invoked, "10.10.10.10"}
      refute_receive :fetch_ip_invoked, @update_timeout - 10
      assert_receive :fetch_ip_invoked
      refute_receive {:update_dns_record_invoked, _}
    end
  end

  test "start_link with missing timeout" do
    assert_raise ArgumentError, fn ->
      Server.start_link(
        fetch_ip_fun: fetch_ip(),
        update_dns_fun: update_dns_record()
      )
    end
  end

  test "start_link with valid missing update_dns_fun" do
    assert_raise ArgumentError, fn ->
      Server.start_link(
        fetch_ip_fun: fetch_ip(),
        timeout: 1000
      )
    end
  end

  test "start_link with valid missing fetch_ip_fun" do
    assert_raise ArgumentError, fn ->
      Server.start_link(
        update_dns_fun: update_dns_record(),
        timeout: 1000
      )
    end
  end

  def fetch_ip do
    pid = self()
    fn ->
      send(pid, :fetch_ip_invoked)
      {:ok, "10.10.10.10"}
    end
  end

  def update_dns_record() do
    pid = self()
    fn ip ->
      send(pid, {:update_dns_record_invoked, ip})
      :ok
    end
  end
end
