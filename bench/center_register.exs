"test/lib/**/*"
|> Path.wildcard
|> Enum.filter(&!File.dir?(&1))
|> Enum.each(&Code.require_file/1) 

require Benchee
require Logger

alias Vayne.Center.GuardHelper

Logger.configure(level: :warn)
GuardHelper.switch_failover()

inputs = %{
  "task 10_000" => Enum.to_list(1..10_000),
}

Benchee.run(
  %{
    "register task" => fn list -> 
       Enum.each(list, fn num -> 
         Vayne.Task.Test.start([num], [type: :repeat])
       end)
    end,
  },
  inputs: inputs,
  parallel: 4
)
