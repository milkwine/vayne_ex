defmodule Vayne.Trigger do

  @moduledoc """
  """

  @type param :: list
  @type state :: any()

  @callback do_init(param) :: {:ok, state} | {:error, String.t}
  @callback do_register(pid, param, state) :: {:ok, state} | {:error, String.t}
  @callback do_clean(pid, state) :: {:ok, state} | {:error , String.t}

  defmacro __using__(_opts) do
    quote do
      require Logger
      use GenServer
      @behaviour Vayne.Trigger

      def start_link do
        GenServer.start_link(__MODULE__, nil, name: __MODULE__)
      end

      def get_self_conf do
        :vayne
        |> Application.get_env(:trigger)
        |> Keyword.get(__MODULE__, [])
      end

      def init(param) do
        Process.flag(:trap_exit, true)
        do_init(param)
      end

      def register(param) do
        GenServer.call(__MODULE__, {:register, param})
      end

      def do_init(_param), do: {:ok, %{}}
      def do_register(_pid, _param, _stat), do: raise "Func not defined!"

      def do_clean(_pid, _stat), do: raise "Func not defined!"
      
      #handle register, monitor process, do_register
      def handle_call({:register, param}, {pid, _ref}, state) do
        case do_register(pid, param, state) do
          {:ok, state} ->
            Process.link(pid)
            {:reply, :ok, state}
          error ->
            Logger.warn fn -> "Register failed, Error: #{inspect error}, Pid: #{inspect pid}" end
            {:reply, error, state}
        end
      end

      #handle down, do_clean
      def handle_info(msg = {:DOWN, _ref, _type, pid, info}, state) do
        Logger.info fn -> "Clean Trigger, Pid: #{inspect pid}" end
        state = do_clean(pid, state)
        {:noreply, state}
      end

      def handle_info({:EXIT, pid, _}, state) do
        Logger.info fn -> "Clean Trigger, Pid: #{inspect pid}" end
        state = do_clean(pid, state)
        {:noreply, state}
      end

      defoverridable [do_init: 1, do_register: 3, do_clean: 2]

    end
  end

  @doc """
  Register task to triggers.
  """
  @spec register(triggers :: list({atom(), term})) :: :ok  | {:error, term}
  def register(triggers) do
    pid = self()
    triggers 
    |> Enum.map(fn {module, param} -> to_module(module).register(param) end)
    |> Enum.find(:ok, &match?({:error, _}, &1))
  end

  @built_in_trigger [Vayne.Trigger.Repeat]

  @doc """
  All triggers child specs
  """
  def trigger_child do
    import Supervisor.Spec
    triggers_conf = Application.get_env(:vayne, :trigger, [])
    triggers = Enum.map(triggers_conf, fn {module, _} -> module end) ++ @built_in_trigger
    triggers
    |> Enum.uniq
    |> Enum.map(fn module -> worker(module, [], name: module) end)
  end

  defp to_module(:repeat), do: Vayne.Trigger.Repeat
  defp to_module(module),  do: module

end
