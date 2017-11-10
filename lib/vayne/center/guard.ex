defmodule Vayne.Center.Guard do

  @moduledoc """
  0. Ping all nodes in conf;
  1. Start center if self is the foremost node alive.
  """
  require Logger

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @empty_stat %{service: nil, mon_ref: nil}

  def init(_) do
    send(self(), :tick)
    {:ok, @empty_stat}
  end

  def handle_info(:tick, state) do
    state    = check_to_spawn(state)
    interval = Application.get_env(:vayne, :guard_tick_interval)
    Logger.debug fn -> "Guard Tick, Stat: #{inspect state}" end
    Process.send_after(self(), :tick, interval)
    {:noreply, state}
  end

  def handle_info(msg = {:DOWN, ref, type, pid, info}, state = %{mon_ref: mon_ref}) do
    state = if ref == mon_ref, do: check_to_spawn(state), else: state
    {:noreply, state}
  end

  def nodes_from_conf do
    conf = Application.get_env(:vayne, :node_list, "node.list")
    conf
      |> File.read!
      |> String.split("\n", trim: true)
      |> Enum.map(&String.to_atom/1)
  end

  def ping_nodes(nodes), do: nodes |> Enum.map(&Node.ping/1)

  def pre_nodes_down?(nodes) do
    node_self  = Node.self

    if node_self in nodes do
      pre_nodes = Enum.take_while(nodes, fn n -> n != node_self end)
      alive = Node.list
      not Enum.any?(pre_nodes, fn n -> n in alive end)
    else
      false
    end

  end

  def spawn_service do
    ret = GenServer.start(Vayne.Center.Service, [], name: {:global, Vayne.Center.Service})
    case ret do
      {:ok, pid} ->
        Logger.info "Spawn Center Service Suc.(pid: #{inspect pid})"
        pid
      error      ->
        Logger.error "Spawn Center Service Failed.(#{inspect error})"
        nil
    end
  end

  def is_local(pid) do
    str_pid = pid |> :erlang.pid_to_list |> to_string
    str_pid =~ ~r/^\<0\./
  end

  def check_to_spawn(stat = %{service: s_pid}) do

    nodes = nodes_from_conf()
    ping_nodes(nodes)

    service_pid = GenServer.whereis({:global, Vayne.Center.Service})

    new_pid = if pre_nodes_down?(nodes) do

      cond do
        not is_pid(service_pid) or not is_list(:rpc.pinfo(service_pid)) ->
          spawn_service()
        is_local(service_pid) ->
          service_pid
        true ->
          Logger.info "Stop Remote Center!"
          GenServer.stop(service_pid, {:take_over, Node.self(), self()})
          spawn_service()
      end

    else
      service_pid
    end

    stat = Map.put(stat, :service, new_pid)
    if is_pid(new_pid) and new_pid != s_pid do
      ref = Process.monitor(new_pid)
      stat |> Map.put(:mon_ref, ref)
    else
      stat
    end
  end

end
