use Mix.Config

config :docker, wrapper_file: "/opt/built/priv/wrapper.sh"

config :docker, backend_proxy_node: :"testchain_backendgateway@testchain-backendgateway.local"
config :docker, backend_proxy_node_reconnection_timeout: 5_000

config :docker, nats: %{host: System.get_env("NATS_HOST"), port: System.get_env("NATS_PORT") |> String.to_integer()}
config :docker, nats_topic: "Prefix.Docker.Request"
config :docker, nats_docker_events_topic: "Prefix.Docker.Events"
