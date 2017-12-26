defmodule Vayne.Task do

  @moduledoc """
  Abstract Vayne Task Behaviour
  """
  @type stat           :: any()
  @type param          :: list()
  @type pk             :: binary()
  @type trigger_params :: list({atom(), term})
  @type timeout        :: timeout()

  @type t :: %__MODULE__{
            type:        module,
            pk:          pk,
            trigger:     trigger_params,
            stat:        stat,
            result:      list,
            timeout:     timeout}

  defstruct type:        Vayne.Task.Test,
            pk:          nil,
            trigger:     nil,
            stat:        nil,
            result:      nil,
            timeout:     nil

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


  defmacro __using__(_opts) do
    quote do
      use GenServer
      @behaviour Vayne.Task
      require Logger

      def start(param, triggers, timeout // 60) do
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
        task = %Vayne.Task{type: __MODULE__, pk: pk, stat: stat}
        {:ok, task}
      end

      def init([param, triggers, timeout]) do
        {:ok, pk} = pk(param)
        {:ok, stat} = do_init(param)
        task = %Vayne.Task{type: __MODULE__, pk: pk, stat: stat, trigger: triggers, timeout: timeout}

        with :ok <- Vayne.Trigger.register(triggers),
             :ok <- Vayne.Center.Service.register(task)
        do
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

      def do_init(param), do: {:ok, param}

      def do_run(_stat), do: raise "#{__MODULE__} function run not defined"

      def do_clean(_stat), do: :ok

      defoverridable [pk: 1, do_init: 1, do_run: 1, do_clean: 1]

    end
  end
end
