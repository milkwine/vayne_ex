defmodule Vayne.Center.Registry do

  @moduledoc """
  """

  @name :vayne_center_registry
  def start do
    @name = :ets.new(@name, [:set, :protected, :named_table])
  end

  def stop do
    :ets.delete(@name)
  end

  #{task.pk, node, pid, task}
  def regist_task(pid, task = %Vayne.Task{}) do
    if :ets.member(@name, task.pk) do
      {:error, "Same task has already exists, pk: #{task.pk}"}
    else
      record = {task.pk, :erlang.node(pid), pid, task}
      if :ets.insert(@name, record) do
        :ok
      else
        {:error, "Insert ets failed, pk: #{task.pk}"}
      end
    end
  end

  def del_task(pid) when is_pid(pid) do
    :ets.match_delete(@name, {:"_", :"_", pid, :"_"})
  end

  def check_task(pid, task = %Vayne.Task{}) do
    case :ets.lookup(@name, task.pk) do
      [] -> false
      [{_pk, _node, t_pid, _task}] -> t_pid == pid
      _ -> false
    end
  end

  def pks do
    @name
    |> :ets.match({:"$1", :"_", :"_", :"_"})
    |> List.flatten
  end

end
