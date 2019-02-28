defmodule Docker do
  @moduledoc """
  Set of docker commands
  """

  require Logger

  alias Docker.Struct.Container

  @docker System.find_executable("docker")

  @doc """
  Get docker executable
  """
  @spec executable!() :: binary
  def executable!(), do: @docker

  # docker run --name=postgres-vdb -e POSTGRES_PASSWORD=postgres -p 5432:5432 -d postgres
  @spec start_rm(Docker.Struct.Container.t()) ::
          {:ok, binary} | {:error, term}
  def start_rm(%Container{id: id}) when bit_size(id) > 0,
    do: {:error, "Could not start container with id"}

  def start_rm(%Container{image: ""}),
    do: {:error, "Could not start container without image"}

  def start_rm(%Container{} = container) do
    Logger.debug("Try to start new container #{inspect(container)}")

    case System.cmd(executable!(), build_start_params(container)) do
      {id, 0} ->
        {:ok, String.replace(id, "\n", "")}

      {err, exit_status} ->
        Logger.error("Failed to start container with code: #{exit_status} - #{inspect(err)}")
        {:error, err}
    end
  end

  @doc """
  Stop running container
  """
  @spec stop(binary) :: :ok | {:error, term}
  def stop(""), do: {:error, "No container id passed"}

  def stop(container_id) do
    Logger.debug("Stopping container #{container_id}")

    case System.cmd(executable!(), ["stop", container_id]) do
      {id, 0} ->
        {:ok, String.replace(id, "\n", "")}

      {err, exit_status} ->
        Logger.error("Failed to stop container with code: #{exit_status} - #{inspect(err)}")
        {:error, err}
    end
  end

  defp build_start_params(%Container{image: image} = container) do
    [
      "run",
      "--rm",
      "-d",
      build_name(container),
      build_ports(container),
      build_env(container),
      image
    ]
    |> List.flatten()
    |> Enum.reject(&(bit_size(&1) == 0))
  end

  defp build_name(%Container{name: ""}), do: ""
  defp build_name(%Container{name: name}), do: ["--name", name]

  defp build_ports(%Container{ports: []}), do: ""

  defp build_ports(%Container{ports: ports}) do
    ports
    |> Enum.map(&build_port/1)
    |> List.flatten()
  end

  defp build_port({port, to_port}), do: ["-p", "#{port}:#{to_port}"]
  defp build_port(port) when is_binary(port), do: ["-p", "#{port}:#{port}"]
  defp build_port(_), do: ""

  defp build_env(%Container{env: []}), do: []

  defp build_env(%Container{env: env}) do
    env
    |> Enum.map(fn {key, val} -> ["--env", "#{key}=#{val}"] end)
    |> List.flatten()
  end
end
