defmodule Vayne.Application do
  use Application              

  @doc false
  def start(_type, _args) do
    import Supervisor.Spec
    children = [               
    #      worker(Vayne.Task.Center, []),  
      worker(Vayne.Center.Guard, [], name: Vayne.Center.Guard),  
    ]
    Supervisor.start_link(children, strategy: :one_for_one, name: Vayne.Application.Supervisor)
  end

end
