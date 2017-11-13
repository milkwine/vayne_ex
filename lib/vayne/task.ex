defmodule Vayne.Task do

  @moduledoc """
  Abstract Vayne Task Behaviour
  """
  @type stat  :: any
  @type param :: list
  @type opt :: list
  @type pk    :: binary
  @type t :: %__MODULE__{
            type:  module,
            param: param,
            opt:   opt,
            pk:    pk,
            stat:  stat
          }

  defstruct type:  Vayne.Task.Test,
            param: ["foo"],
            opt:   [schedule: :repeat, interval: 60],
            pk:    nil,
            stat:  nil

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

      def start(param, opt) do
        GenServer.start(__MODULE__, [param, opt])
      end

      def init([param, opt]) do
        {:ok, pk} = pk(param)
        {:ok, stat} = init_stat(param)
        #register center pk, ok return stat, or clean stat
        task = %Vayne.Task{type: __MODULE__, pk: pk, param: param, opt: opt, stat: stat}
        {:ok, task}
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
