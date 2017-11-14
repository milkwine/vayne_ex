defmodule VayneTaskTestTest do
  use ExUnit.Case
  doctest Vayne.Task.Test

  test "make task" do
     {:ok, pid} = Vayne.Task.Test.start_no_register(["p1", "p2"], [type: :repeat])

     gen_stat = %Vayne.Task{opt: [type: :repeat], param: ["p1", "p2"], pk: "Elixir.Vayne.Task.Test#82935458",
      stat: ["p1", "p2"], type: Vayne.Task.Test}

    assert gen_stat == :sys.get_state(pid)
  end

end
