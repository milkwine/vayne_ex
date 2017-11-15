defmodule Vayne.Center.GuardTest do
  use ExUnit.Case, async: false
  doctest Vayne.Center.Guard
  alias Vayne.Center.GuardHelper

  @tag :distributed
  test "normal" do
    GuardHelper.switch_normal()
    service_pid = GenServer.whereis({:global, Vayne.Center.Service})
    assert :"vayne-1@localhost" ==  :erlang.node(service_pid)
    assert {:error, :no_cache} = Cachex.size(:task_cache)
    assert {:error, :no_cache} = Cachex.size(:running_cache)
  end

  @tag :distributed
  test "fail over" do
    GuardHelper.switch_failover()
    service_pid = GenServer.whereis({:global, Vayne.Center.Service})
    assert :"vayne-2@localhost" ==  :erlang.node(service_pid)
    assert {:ok, _} = Cachex.size(:task_cache)
    assert {:ok, _} = Cachex.size(:running_cache)
  end

  @tag :distributed
  test "take over" do
    GuardHelper.switch_failover()
    service_pid = GenServer.whereis({:global, Vayne.Center.Service})
    assert :"vayne-2@localhost" ==  :erlang.node(service_pid)
    assert {:ok, _} = Cachex.size(:task_cache)
    assert {:ok, _} = Cachex.size(:running_cache)

    GuardHelper.switch_normal()
    service_pid = GenServer.whereis({:global, Vayne.Center.Service})
    assert :"vayne-1@localhost" ==  :erlang.node(service_pid)
    assert {:error, :no_cache} = Cachex.size(:task_cache)
    assert {:error, :no_cache} = Cachex.size(:running_cache)
  end

  @tag :distributed
  test "task register" do
    GuardHelper.switch_failover()
    {:ok, pid} = Vayne.Task.Test.start(["p1", "p2"], [type: :repeat])

    gen_stat = %Vayne.Task{opt: [type: :repeat], param: ["p1", "p2"], pk: "Elixir.Vayne.Task.Test#82935458",
      stat: ["p1", "p2"], type: Vayne.Task.Test}

    assert gen_stat == :sys.get_state(pid)
    assert Cachex.get!(:running_cache, gen_stat.pk) == pid
  end

end
