
"#{Path.dirname(__ENV__.file)}/lib/**/*"
|> Path.wildcard
|> Enum.filter(&!File.dir?(&1))
|> Enum.each(&Code.require_file/1) 

unless Vayne.Center.GuardHelper.can_test_distributed do
  ExUnit.configure(exclude: [distributed: true])
end

ExUnit.start()
