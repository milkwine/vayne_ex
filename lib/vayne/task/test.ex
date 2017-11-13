defmodule Vayne.Task.Test do

  @moduledoc """
  Implimentation of Vayne.Task Behaviour
  """
  use Vayne.Task

  def run(_stat) do
    IO.puts "run test task!"
    :ok
  end
end
