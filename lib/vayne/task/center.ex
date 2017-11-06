defmodule Vayne.Task.Center do

  @moduledoc """
  Stores tasks globally.

  Worker should grab task from Center.

  Recored which worker hold the task.
  """

  def start_link do
    GenServer.start_link(__MODULE__, [], name: {:global, __MODULE__})
  end

  def init(_) do
    table = :ets.new(:vayne_tasks, [:set, :protected])
    {:ok, table}
  end

  def handle_call(:all, _from, table) do
    list = :ets.tab2list(table)
    IO.puts "here!"

    { :reply, list, table }
  end

  def diff_task(task), do: GenServer.call({:global, __MODULE__}, {:diff, task})

  def load_task(task), do: GenServer.call({:global, __MODULE__}, {:load, task})

  def all_task, do: GenServer.call({:global, __MODULE__}, :all)

  def clean_task, do: GenServer.call({:global, __MODULE__}, :clean)

  def get_task(num \\ 10), do: GenServer.call({:global, __MODULE__}, {:get, num})

  #@spec commit_task([binary, pid]) :: :ok | :error
  #[{key, pid}]
  def commit_task(tasks), do: GenServer.call({:global, __MODULE__}, {:commit, tasks})

  def query_task(keys), do: GenServer.call({:global, __MODULE__}, {:query, keys})


end
