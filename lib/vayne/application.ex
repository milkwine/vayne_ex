defmodule Vayne.Application do
  use Application

  @moduledoc false

  def start(_type, _args) do
    import Supervisor.Spec
    children = [
      worker(Vayne.Center.Guard, [], name: Vayne.Center.Guard),
    ] ++ Vayne.Trigger.trigger_child()

    Supervisor.start_link(children, strategy: :one_for_one, name: Vayne.Application.Supervisor)
  end

end
