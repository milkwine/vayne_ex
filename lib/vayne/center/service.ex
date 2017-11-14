defmodule Vayne.Center.Service do
  use GenServer
  require Logger

  @moduledoc """
  Stores tasks globally.

  Worker should grab task from Center.

  Recored which worker hold the task.
  """

  @running :running_cache
  @task    :task_cache
  def init(_) do
    {:ok, _pid} = Cachex.start_link(@running, [])
    {:ok, _pid} = Cachex.start_link(@task, [])
    {:ok, nil}
  end

  def terminate({:take_over, node, guard_pid}, _state) do
    Logger.info "Take over have been called!(Node: #{inspect node}, Guard pid: #{inspect guard_pid})"
  end

  def terminate(reason, _state) do
    Logger.info "Terminate, reason: #{inspect reason}"
  end

  def handle_call({:register, task}, {pid, _ref}, stat) do
    with {:ok, false} <- Cachex.exists?(@running, task.pk),
         {:ok, true}  <- Cachex.set(@running, task.pk, pid)
    do
      {:reply, :ok, stat}
    else
      _ ->
        {:reply, :error, stat}
    end
  end

  def register(task), do: GenServer.call({:global, __MODULE__}, {:register, task})

end
