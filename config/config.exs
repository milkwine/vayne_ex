# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :vayne, trigger: [
  {Vayne.Trigger.Repeat, [interval: :timer.seconds(5)]}
]

if Mix.env == :test do         
  config :vayne, node_list: ".test_node.list"
  config :vayne, guard_tick_interval: 1_000
else
  config :vayne, node_list: "node.list"
  config :vayne, guard_tick_interval: 5_000
end

config :logger, level: :info
