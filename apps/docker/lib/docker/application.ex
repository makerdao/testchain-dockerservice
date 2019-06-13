defmodule Docker.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Starts a worker by calling: Docker.Worker.start_link(arg)
      # {Docker.Worker, arg},
      Docker.ContainerSupervisor,
      Docker.PortMapper,
      Docker.Events,
      Docker.Nats,
      Docker.Cmd,
      Docker.BackendProxyNodeConnector,
      Docker.NetworkRemover
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Docker.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
