defmodule Vayne.Trigger.Repeat do

  @moduledoc """
  """

  use Vayne.Trigger

  @interval 1_000
  defp tick do
    conf = get_self_conf()
    interval = Keyword.get(conf, :interval, @interval)
    Process.send_after(self(), :check_task, interval)
  end

  def do_init(_param) do
    tick()
    {:ok, %{}}
  end

  @doc """
  Registe task to the trigger.

  ## Param keyword options:

  * `:interval` - How long dose the task will be triggered
  trigger right now. Defaults to 60_000
  * `:random` - Trigger it after some random time to avoid a mount of tasks is running
  at the same time. Defaults to true.
  * `:random_factor` - Defaults to 0.2.
  """
  def do_register(pid, param, state) do
    case parse_param(param) do
      {:ok, repeat_stat} -> 
        state = Map.put(state, pid, repeat_stat)
        {:ok, state}
      error ->
        {:error, error}
    end
  end

  def do_clean(pid, state) do
    {:ok, Map.delete(state, pid)}
  end

  def handle_info(:check_task, state) do

    now = System.system_time(:second)

    state = state 
    |> Enum.filter(fn {_pid, %{next: next}} -> now >= next end)
    |> Enum.reduce(state, fn({pid, trigger_stat}, acc) -> run_task(pid, trigger_stat, acc) end)

    tick()
    {:noreply, state}
  end

  defp run_task(pid, %{next: next, interval: interval}, acc) do
   case Vayne.Task.run(pid) do
      :ok ->
        Map.put(acc, pid, %{next: next + interval, interval: interval})
      {:error, reason} ->
        Logger.warn fn -> "Trigger task failed, task: #{inspect pid}, reason: #{inspect reason}" end
        acc
    end
  end

  @default_interval      60_000
  @default_random        true
  @default_random_factor 0.2

  defp parse_param(params) do
    now           = System.system_time(:second)
    interval      = Keyword.get(params, :interval, @default_interval)
    random        = Keyword.get(params, :random, @default_random)
    random_factor = Keyword.get(params, :random_factor, @default_random_factor)

    r = round(interval * random_factor)
    next = if random && r > 0 do
      now + :rand.uniform(r)
    else
      now
    end

    {:ok, %{next: next, interval: interval}}
  end

end
