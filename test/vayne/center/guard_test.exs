defmodule Vayne.Center.GuardTest do
  use ExUnit.Case, async: false
  doctest Vayne.Center.Guard
  alias Vayne.Center.GuardHelper

  @tag :distributed
  test "normal" do
    GuardHelper.switch_normal()
    service_pid = GenServer.whereis({:global, Vayne.Center.Service})
    assert :"vayne-1@localhost" ==  :erlang.node(service_pid)
  end

  @tag :distributed
  test "fail over" do
    GuardHelper.switch_failover()
    service_pid = GenServer.whereis({:global, Vayne.Center.Service})
    assert :"vayne-2@localhost" ==  :erlang.node(service_pid)
  end

  @tag :distributed
  test "take over" do
    GuardHelper.switch_failover()
    service_pid = GenServer.whereis({:global, Vayne.Center.Service})
    assert :"vayne-2@localhost" ==  :erlang.node(service_pid)

    GuardHelper.switch_normal()
    service_pid = GenServer.whereis({:global, Vayne.Center.Service})
    assert :"vayne-1@localhost" ==  :erlang.node(service_pid)
  end


end
