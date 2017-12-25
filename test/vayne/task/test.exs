defmodule VayneTaskTestTest do
  use ExUnit.Case
  doctest Vayne.Task.Test

  test "make task" do
    {:ok, pid} = Vayne.Task.Test.start(["p1", "p2"], [{:repeat, [interval: 10_000]}])

    gen_stat = %Vayne.Task{pk: "Elixir.Vayne.Task.Test#82935458", state: ["p1", "p2"],
     statistics: nil, trigger: [repeat: [interval: 10000]], type: Vayne.Task.Test}

    assert gen_stat == :sys.get_state(pid)
  end

end
