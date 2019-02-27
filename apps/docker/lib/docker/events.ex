defmodule Docker.Events do
  @moduledoc """
  Module that handles
  """
  use GenServer

  require Logger

  @doc false
  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @doc false
  def init(_) do
    port = start_executable()
    Logger.debug("New docker events spawned with port #{inspect(port)}")

    {:ok, port}
  end

  @doc false
  def terminate(reason, port) do
    Logger.debug("Got termination reason: #{inspect(reason)}. Closing port.")
    Port.info(port)
  end

  @doc false
  def handle_info({:DOWN, _ref, :port, _, reason}, port) do
    Logger.info("Got port failure with reason #{inspect(reason)}")
    {:stop, :failed, port}
  end

  @doc false
  def handle_info({_port, {:data, msg}}, port) do
    Logger.debug("Got docker event: #{inspect(msg)}")
    {:noreply, port}
  end

  def handle_info(msg, port) do
    IO.inspect(msg)
    {:noreply, port}
  end

  # Start new docker events executable
  defp start_executable() do
    wrapper =
      :docker
      |> Application.get_env(:wrapper_file)
      |> Path.absname()

    unless File.exists?(wrapper) do
      raise "No wrapper file exists in #{wrapper}"
    end

    unless docker = System.find_executable("docker") do
      raise "No docker executable found in system !"
    end

    port =
      {:spawn_executable, wrapper}
      |> Port.open([:binary, :exit_status, args: [docker, "events"]])

    Port.monitor(port)
    Process.link(port)

    port
  end
end
