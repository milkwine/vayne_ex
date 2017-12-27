defmodule Vayne.Task do

  def x(type) do
    {:ok, pid} = Vayne.Task.Test.start(type, [], 5_000)
    Vayne.Task.run(pid)
    pid 
  end

  @moduledoc """
  Abstract Vayne Task Behaviour
  """
  @type stat           :: any()
  @type param          :: list()
  @type pk             :: binary()
  @type trigger_param  :: {atom(), term}
  @type result         :: {non_neg_integer, atom, term}

  @type t :: %__MODULE__{
            pk:          pk,
            trigger:     list(trigger_param),
            stat:        stat,
            results:      list(result),
            timeout:     timeout,
            task:        Task.t,
            start_time:  integer}

  defstruct pk:          nil,
            trigger:     nil,
            stat:        nil,
            results:      [],
            timeout:     nil,
            task:        nil,
            start_time:  nil

  @doc """
  Generate vayne task pk according to the params
  """
  @callback pk(param) :: {:ok, String.t} | {:error, String.t}

  @doc """
  Initialize task stat
  """
  @callback do_init(param) :: {:ok, stat} | {:error, String.t}

  @doc """
  Run the task with stat
  """
  @callback do_run(stat) :: :ok | {:error, String.t}

  @doc """
  Clean task stat
  """
  @callback do_clean(stat) :: :ok | {:error, String.t}


  def run(pid),  do: GenServer.call(pid, :run)

  def stat(pid), do: GenServer.call(pid, :stat)

  def apply_run(parent, m, f, a) do
    result = apply(m, f, a)
    send(parent, {:result, result})
  end

  defmacro __using__(_opts) do
    quote do
      use GenServer
      @behaviour Vayne.Task
      require Logger

      def start(param, triggers, timeout \\ 60_000) do
        GenServer.start(__MODULE__, [param, triggers, timeout])
      end

      @doc """
      Should never use this function; Only for unite test.
      """
      def start_no_register(param, triggers) do
        GenServer.start(__MODULE__, {:no_register, [param, triggers]})
      end

      def init({:no_register, [param, triggers, timeout]}) do
        {:ok, pk} = pk(param)
        {:ok, stat} = do_init(param)
        task = %Vayne.Task{pk: pk, stat: stat}
        {:ok, task}
      end

      def init([param, triggers, timeout]) do
        {:ok, pk} = pk(param)
        {:ok, stat} = do_init(param)
        task = %Vayne.Task{pk: pk, stat: stat, trigger: triggers, timeout: timeout}

        with :ok <- Vayne.Trigger.register(triggers),
             :ok <- Vayne.Center.Service.register(task)
        do
          Process.flag(:trap_exit, true)
          {:ok, task}
        else
          {:error, error} ->
            do_clean(stat)
            Logger.info fn -> "Init task failed: #{error}, param: #{inspect param}, trigger: #{inspect triggers}" end
            {:error, error}
        end

      end

      def terminate(reason, t = %Vayne.Task{}) do
        do_clean(t.stat)
        Logger.info fn -> "Task stop, reason: #{inspect reason}, task: #{inspect t}" end
      end

      def pk(param) do
        pk = "#{__MODULE__}##{:erlang.phash2(param)}"
        {:ok, pk}
      end


      #task exit normal
      def handle_info({:EXIT, _from, :normal}, t), do: {:noreply, t}

      #task exit timeout
      def handle_info({:EXIT, _from, :timeout}, t), do: {:noreply, t}

      #task exit error
      def handle_info({:EXIT, _from, error}, t) do
        new_stat= fill_result(t, :error, error)
        {:noreply, new_stat}
      end
      
      #task result get
      def handle_info({:result, result}, t) do
        new_stat= fill_result(t, :ok, result)
        {:noreply, new_stat}
      end

      #task timeout
      def handle_info(:timeout, t = %Vayne.Task{task: pid}) when is_pid(pid) do
        Process.exit(pid, :timeout)
        new_stat= fill_result(t, :timeout)
        {:noreply, new_stat}
      end

      def handle_info(:timeout, t = %Vayne.Task{}), do: {:noreply, t}

      def handle_call(:run, {_pid, _ref}, t = %Vayne.Task{}) do
        if t.task != nil do
          {:reply, {:error, :still_running}, t}
        else
          task = spawn_link(Vayne.Task, :apply_run, [self(), __MODULE__, :do_run, [t.stat]])
          t = t
          |> Map.put(:task, task)
          |> Map.put(:start_time, :os.system_time(:second))
          |> IO.inspect

          Process.send_after(self(), :timeout, t.timeout)
          {:reply, :ok, t}
        end
      end

      def handle_call(:stat, {_pid, _ref}, t = %Vayne.Task{}) do
        {:reply, t, t}
      end

      @result_keep 3
      defp fill_result(t=%Vayne.Task{}, type, result \\ nil) do
        r = {t.start_time, type, result}
        results = [r | t.results] |> Enum.take(@result_keep)
        t 
        |> Map.put(:results, results)
        |> Map.put(:start_time, nil)
        |> Map.put(:task, nil)
      end

      def do_init(param), do: {:ok, param}
      def do_run(_stat), do: raise "#{__MODULE__} function run not defined"
      def do_clean(_stat), do: :ok

      defoverridable [pk: 1, do_init: 1, do_run: 1, do_clean: 1]

    end
  end
end
