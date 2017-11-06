defmodule VayneTaskTestTest do
  use ExUnit.Case
  doctest Vayne.Task.Test

  test "make task" do
    target = %Vayne.Task{param: [:foo, :bar], pk: "Vayne.Task:foobar", type: Vayne.Task.Test}
    assert {:ok, ^target} = Vayne.Task.make(Vayne.Task.Test, [:foo, :bar])
  end

end
