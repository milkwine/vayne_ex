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
  def start_link do
    GenServer.start(__MODULE__, [], name: {:global, __MODULE__})
  end

  def init(_) do
    {:ok, _pid} = Cachex.start_link(@running, [])
    {:ok, _pid} = Cachex.start_link(@task, [])
    {:ok, nil}
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
