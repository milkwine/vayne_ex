defmodule VayneTaskTestTest do
  use ExUnit.Case

  alias Vayne.Center.GuardHelper

  setup do
    if Vayne.Center.GuardHelper.can_test_distributed do
      GuardHelper.switch_failover()
    else
      GuardHelper.switch_normal()
    end
  end

  test "normal" do
    {:ok, pid} = Vayne.Task.Test.start(:normal, [])
    Vayne.Task.run(pid)
    Process.sleep(2_000)
    status = Vayne.Task.stat(pid)
    assert status.last.type == :ok
    Vayne.Task.stop(pid)
  end

  test "timeout" do
    {:ok, pid} = Vayne.Task.Test.start(:timeout, [], 4_000)
    Vayne.Task.run(pid)
    Process.sleep(5_000)
    status = Vayne.Task.stat(pid)
    assert status.last.type == :timeout
    Vayne.Task.stop(pid)
  end

  test "error" do
    {:ok, pid} = Vayne.Task.Test.start(:error, [])
    Vayne.Task.run(pid)
    Process.sleep(2_000)
    status = Vayne.Task.stat(pid)
    assert status.last.type == :error
    Vayne.Task.stop(pid)
  end

  test "task killed and start again" do
    {:ok, pid} = Vayne.Task.Test.start(:test_kill, [])
    Vayne.Task.stop(pid)

    assert {:ok, pid} = Vayne.Task.Test.start(:test_kill, [])
    Vayne.Task.stop(pid)

  end

  test "task should stop when center not exist the task" do

    {:ok, pid} = Vayne.Task.Test.start(:test_check_center, [])

    center = GenServer.whereis({:global, Vayne.Center.Service})

    send(center, {:DOWN, make_ref(), :process, pid, :fake_down})

    Process.sleep(6_000)

    assert false == Process.alive?(pid)
  end

  test "task killed and no more job process left" do
  end
end
