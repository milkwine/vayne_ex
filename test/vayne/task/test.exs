defmodule VayneTaskTestTest do
  use ExUnit.Case

  alias Vayne.Center.GuardHelper

  setup do
    GuardHelper.switch_normal()
  end

  test "normal" do
    {:ok, pid} = Vayne.Task.Test.start(:normal, [])
    Vayne.Task.run(pid)
    Process.sleep(2_000)
    status = Vayne.Task.stat(pid)
    assert status.last.type == :ok
  end

  test "timeout" do
    {:ok, pid} = Vayne.Task.Test.start(:timeout, [], 4_000)
    Vayne.Task.run(pid)
    Process.sleep(5_000)
    status = Vayne.Task.stat(pid)
    assert status.last.type == :timeout
  end

  test "error" do
    {:ok, pid} = Vayne.Task.Test.start(:error, [])
    Vayne.Task.run(pid)
    Process.sleep(2_000)
    status = Vayne.Task.stat(pid)
    assert status.last.type == :error
  end

  test "task killed and start again" do
    {:ok, pid} = Vayne.Task.Test.start(:test_kill, [])
    Vayne.Task.stop(pid)

    assert {:ok, _} = Vayne.Task.Test.start(:test_kill, [])

  end

  test "task killed and no more job process left" do
  end
end
