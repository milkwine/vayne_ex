defmodule Vayne.Trigger.RepeatTest do
  use ExUnit.Case, async: false

  alias Vayne.Center.GuardHelper

  setup do
    if Vayne.Center.GuardHelper.can_test_distributed do
      GuardHelper.switch_failover()
    else
      GuardHelper.switch_normal()
    end
  end

  test "test normal trigger" do
    assert {:ok, pid} = Vayne.Task.Test.start(:normal, [repeat: [interval: 2]], 10)
    Process.sleep(4_000)
    status = Vayne.Task.stat(pid)
    assert status.last.type == :ok
    Vayne.Task.stop(pid)
  end

  test "task should die if trigger was killed" do
    assert {:ok, pid} = Vayne.Task.Test.start(:test_die, [repeat: [interval: 2]], 10)
    GenServer.stop(Vayne.Trigger.Repeat, :shutdown)
    Process.sleep(1_000)
    assert Process.alive?(pid) == false

    #trigger should be restarted by supervisor
    assert is_pid(GenServer.whereis(Vayne.Trigger.Repeat)) == true
  end

end
