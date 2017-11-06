defmodule Vayne.Task.Test do

  @moduledoc """
  Implimentation of Vayne.Task Behaviour
  """

  @behaviour Vayne.Task

  def pk(params) do
    {:ok, "Vayne.Task:#{Enum.join(params)}"}
  end

  def init(_params) do
    {:ok, nil}
  end

  def run(_stat) do
    IO.puts "run test task!"
    :ok
  end

  def clean(_stat) do
    :ok
  end
end
