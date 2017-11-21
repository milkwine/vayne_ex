defmodule Vayne.Trigger.Repeat do

  use Vayne.Trigger

  @interval 3_000
  defp tick do
    conf = get_self_conf()
    interval = Keyword.get(conf, :interval, @interval)
    Process.send_after(:self, :check_task, interval)
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
      {:ok, trigger_stat} -> 
        state = Map.put(state, pid, trigger_stat)
        {:ok, state}
      error ->
        error
    end
  end

  def do_clean(pid, state) do
    :ok
  end

  def handle_info(:check_task, state) do
    tick()
    {:noreply, state}
  end

  @default_interval      60_000
  @default_random        true
  @default_random_factor 0.2

  defp parse_param(params) do
    now           = System.system_time(:second)
    interval      = Keyword.get(params, :interval, @default_interval)
    random        = Keyword.get(params, :random, @default_random)
    random_factor = Keyword.get(params, :random_factor, @default_random_factor)

    next = if random do
      now + :rand.uniform(round(interval * random_factor))
    else
      now
    end

    {:ok, %{next: next, interval: interval}}
  end

end
