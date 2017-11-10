defmodule Vayne.Center.Service do
  require Logger

  @moduledoc """
  Stores tasks globally.

  Worker should grab task from Center.

  Recored which worker hold the task.
  """

  def init(_) do
    table = :ets.new(:vayne_tasks, [:set, :protected])
    {:ok, table}
  end

  def terminate({:take_over, node, guard_pid}, state) do
    Logger.info "Take over have been called!(Node: #{inspect node}, Guard pid: #{inspect guard_pid})"
  end

  def terminate(reason, state) do
    Logger.info "Terminate, reason: #{inspect reason}"
  end

  def handle_call(:all, _from, table) do
    list = :ets.tab2list(table)
    {:reply, list, table}
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
