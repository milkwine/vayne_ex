defmodule Vayne.Center.Service do
  use GenServer
  require Logger
  alias Vayne.Center.Registry

  @moduledoc """
  Stores tasks globally.

  Worker should grab task from Center.

  Recored which worker hold the task.
  """

  def start_link do
    GenServer.start(__MODULE__, [], name: {:global, __MODULE__})
  end

  def init(_) do
    Registry.start()
    {:ok, nil}
  end

  def handle_info({:DOWN, ref, :process, pid, reason}, stat) do
    if Registry.del_task(pid) do
      Process.demonitor(ref)
      Logger.info fn -> "Task down, Reason: #{inspect reason}, task: #{inspect pid}" end
    end
    {:noreply, stat}
  end

  def handle_call({:register, task}, {pid, _ref}, stat) do

    ret = Registry.regist_task(pid, task)
    if :ok == ret, do: Process.monitor(pid)
    {:reply, ret, stat}

  end

  def handle_call({:check, task}, {pid, _ref}, stat) do
    ret = Registry.check_task(pid, task)
    {:reply, ret, stat}
  end

  def handle_call(:all, {_pid, _ref}, stat) do

    {:reply, Registry.pks(), stat}
  end

  def terminate(_reason, _stat) do
    Registry.stop()
  end

  def register(task), do: GenServer.call({:global, __MODULE__}, {:register, task})

  def all_tasks, do: GenServer.call({:global, __MODULE__}, :all)

  def task_should_alive?(task), do: GenServer.call({:global, __MODULE__}, {:check, task})

end
