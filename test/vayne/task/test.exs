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
    task = Vayne.Task.stat(pid)
    assert match?([{_, :ok, _}], task.results)
  end

  test "timeout" do
    {:ok, pid} = Vayne.Task.Test.start(:timeout, [], 4_000)
    Vayne.Task.run(pid)
    Process.sleep(5_000)
    task = Vayne.Task.stat(pid)
    assert match?([{_, :timeout, _}], task.results)
  end

  test "error" do
    {:ok, pid} = Vayne.Task.Test.start(:error, [])
    Vayne.Task.run(pid)
    Process.sleep(2_000)
    task = Vayne.Task.stat(pid)
    assert match?([{_, :error, _}], task.results)
  end

end
