defmodule Vayne.Task.Test do

  @moduledoc """
  Implimentation of Vayne.Task Behaviour
  """
  use Vayne.Task

  def do_run(type) do
    case type do
      :timeout -> Process.sleep(10_000)
      :error -> 1/0
      _ -> "result"
    end
  end
end
