defmodule Vayne.Center.Supervisor do

  @moduledoc """
  """
  def start do
    import Supervisor.Spec
    children = [
      worker(Vayne.Center.Service, [])
    ]
    Supervisor.start_link(children, strategy: :one_for_one, name: {:global, __MODULE__})
  end

end
