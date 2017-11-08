defmodule Vayne.Center.GuardHelper do

  def file, do: ".test_node.list"

  def self_node, do: :"vayne-2@localhost"

  def switch_normal do
    ~w(
    vayne-1@localhost
    vayne-2@localhost
    vayne-3@localhost
    ) |> write_nodes_file
    tick()
  end

  def switch_failover do
    ~w(
    vayne-2@localhost
    vayne-3@localhost
    ) |> write_nodes_file
    Node.list |> Enum.map(&Node.disconnect/1)
    tick()
  end

  defp tick do
    interval = Application.get_env(:vayne, :guard_tick_interval, 5_000)
    send(Vayne.Center.Guard, :tick)
    Process.sleep(interval * 2)
  end

  defp write_nodes_file(nodes) do
    cont = Enum.join(nodes, "\n")
    File.write!(file(), cont)
  end

end
