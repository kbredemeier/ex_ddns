defmodule ExDDNS.State.ServerTest do
  use ExUnit.Case

  alias ExDDNS.State.Server

  test "start_link with valid opts" do
    {:ok, pid} =
      Server.start_link(
        fetch_ip_fun: &fetch_current_ip/0,
        update_dns_fun: &update_dns_record/0,
        timeout: 1000
      )
    assert state = Server.get_state(pid)
    assert is_binary(state.current_ip)
    assert %DateTime{} = state.last_update
    assert %DateTime{} = state.last_check
  end

  test "start_link with valid missing timeout" do
    assert_raise ArgumentError, fn ->
      Server.start_link(
        fetch_ip_fun: &fetch_current_ip/0,
        update_dns_fun: &update_dns_record/0
      )
    end
  end

  test "start_link with valid missing update_dns_fun" do
    assert_raise ArgumentError, fn ->
      Server.start_link(
        fetch_ip_fun: &fetch_current_ip/0,
        timeout: 1000
      )
    end
  end

  test "start_link with valid missing fetch_ip_fun" do
    assert_raise ArgumentError, fn ->
      Server.start_link(
        update_dns_fun: &update_dns_record/0,
        timeout: 1000
      )
    end
  end

  def fetch_current_ip, do: {:ok, "10.10.10.10"}
  def update_dns_record, do: :ok
end
