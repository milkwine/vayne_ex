defmodule Vayne.Center.Service do
  use GenServer
  require Logger

  @moduledoc """
  Stores tasks globally.

  Worker should grab task from Center.

  Recored which worker hold the task.
  """

  @running_cache :running_cache
  @pid_cache     :task_cache
  def start_link do
    GenServer.start(__MODULE__, [], name: {:global, __MODULE__})
  end

  def init(_) do
    {:ok, _pid} = Cachex.start_link(@running_cache, [])
    {:ok, _pid} = Cachex.start_link(@pid_cache,     [])
    {:ok, nil}
  end

  def handle_info({:DOWN, ref, :process, pid, reason}, stat) do
    with {:ok, pk}   <- Cachex.get(@pid_cache, pid),
         {:ok, task} <- Cachex.get(@running_cache, pk),
         {:ok, true} <- Cachex.del(@running_cache, pk)
    do
      Process.demonitor(ref)
      Logger.info fn -> "Task down, Reason: #{inspect reason}, task: #{inspect task}" end
    end
    {:noreply, stat}
  end

  #       Maybe should use `Ets` instead of `Cachex`.
  # TODO: Error will happen when set `running_cache` success and set `pid_cache` failed.
  def handle_call({:register, task}, {pid, _ref}, stat) do

    with {:ok, false} <- Cachex.exists?(@running_cache, task.pk),
         {:ok, true}  <- Cachex.set(@running_cache, task.pk, task),
         {:ok, true}  <- Cachex.set(@pid_cache, pid, task.pk)
    do
      Process.monitor(pid)
      {:reply, :ok, stat}
    else
      {:ok, true} ->
        {:reply, {:error, "Same task has already exists, pk: #{task.pk}"}, stat}
      _ ->
        {:reply, {:error, "Set cache failed, pk: #{task.pk}"}, stat}
    end
  end

  def handle_call(:all, {_pid, _ref}, stat) do

    keys = Cachex.keys!(@running_cache)
    {:reply, keys, stat}
  end

  def register(task), do: GenServer.call({:global, __MODULE__}, {:register, task})

  def all_tasks, do: GenServer.call({:global, __MODULE__}, :all)

end
