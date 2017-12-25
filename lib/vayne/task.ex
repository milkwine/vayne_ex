defmodule Vayne.Task do

  @moduledoc """
  Abstract Vayne Task Behaviour
  """
  @type stat  :: any
  @type param :: list
  @type pk    :: binary

  defstruct type:        Vayne.Task.Test,
            pk:          nil,
            trigger:     nil,
            state:       nil,
            statistics:  nil

  @doc """
  Generate vayne task pk according to the params
  """
  @callback pk(param) :: {:ok, String.t} | {:error, String.t}

  @doc """
  Initialize task stat
  """
  @callback init_stat(param) :: {:ok, stat} | {:error, String.t}

  @doc """
  Run the task with stat
  """
  @callback run(stat) :: :ok | {:error, String.t}

  @doc """
  Clean task stat
  """
  @callback clean(stat) :: :ok | {:error, String.t}

  defmacro __using__(_opts) do
    quote do
      use GenServer
      @behaviour Vayne.Task
      require Logger

      def start(param, triggers) do
        GenServer.start(__MODULE__, [param, triggers])
      end

      @doc """
      Should never use this function; Only for unite test.
      """
      def start_no_register(param, triggers) do
        GenServer.start(__MODULE__, {:no_register, [param, triggers]})
      end

      def init({:no_register, [param, triggers]}) do
        {:ok, pk} = pk(param)
        {:ok, stat} = init_stat(param)
        task = %Vayne.Task{type: __MODULE__, pk: pk, state: stat}
        {:ok, task}
      end

      def init([param, triggers]) do
        {:ok, pk} = pk(param)
        {:ok, stat} = init_stat(param)
        task = %Vayne.Task{type: __MODULE__, pk: pk, state: stat, trigger: triggers}

        with :ok <- Vayne.Trigger.register(triggers),
             :ok <- Vayne.Center.Service.register(task)
        do
          {:ok, task}
        else
          {:error, error} ->
            clean(stat)
            Logger.info fn -> "Init task failed: #{error}, param: #{inspect param}, trigger: #{inspect triggers}" end
            {:error, error}
        end

      end

      def terminate(reason, t = %Vayne.Task{}) do
        clean(t.stat)
        Logger.info fn -> "Task stop, reason: #{inspect reason}, task: #{inspect t}" end
      end

      def pk(param) do
        pk = "#{__MODULE__}##{:erlang.phash2(param)}"
        {:ok, pk}
      end

      def init_stat(param), do: {:ok, param}

      def run(_stat), do: raise "#{__MODULE__} function run not defined"

      def clean(_stat), do: :ok

      defoverridable [pk: 1, init: 1, run: 1, clean: 1]

    end
  end
end
