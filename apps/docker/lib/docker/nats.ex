defmodule Docker.Nats do
  @moduledoc """
  Nats handler. 
  """
  use GenServer

  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_) do
    nats_config = Application.get_env(:docker, :nats)
    {:ok, conn} = Gnat.start_link(nats_config)
    Logger.debug("Connected to Nats.io with config #{inspect(nats_config)}")

    # {:ok, sub} = Gnat.sub(conn, self(), topic())

    # {:ok, %{conn: conn, sub: sub}}
    {:ok, %{conn: conn}}
  end

  def handle_cast({:push, {topic, event}}, %{conn: conn} = state) when is_binary(topic) do
    Gnat.pub(conn, topic, Jason.encode!(event), [])
    {:noreply, state}
  end

  def handle_cast({:push, {topic, event, reply_to}}, %{conn: conn} = state) do
    Gnat.pub(conn, topic, Jason.encode!(event), reply_to: reply_to)
    {:noreply, state}
  end

  def handle_info({:msg, %{body: body, reply_to: nil}}, state) do
    Logger.debug("Unknown request: #{inspect(body)}")
    {:noreply, state}
  end

  def handle_info({:msg, %{body: body, reply_to: reply_to}}, %{conn: conn} = state) do
    Logger.debug("Got request and will reply to #{reply_to}")

    case Jason.decode(body, keys: :atoms) do
      {:ok, request} ->
        # Run operation async and in case of falure - we dont care
        spawn(fn ->
          request
          |> action()
          |> reply(reply_to, conn)
        end)

      {:error, err} ->
        Logger.error("Failed to parse request: #{inspect(err)}")
        reply("Error parsing request", reply_to, conn)
    end

    {:noreply, state}
  end

  @doc """
  Send notification
  """
  @spec push({binary, term}) :: :ok
  def push(notification),
    do: GenServer.cast(__MODULE__, {:push, notification})

  defp action(%{action: "stop", data: id}) when is_binary(id),
    do: Docker.stop(id)

  defp action(%{action: "start", data: data}) do
    container =
      Docker.Struct.Container
      |> struct(data)

    Docker
    |> Task.async(:start_rm, [container])
    |> Task.await()
  end

  # Send message to nats
  defp reply({:ok, data}, topic, conn),
    do: reply(%{type: "success", data: data}, topic, conn)

  defp reply({:error, error}, topic, conn),
    do: reply(%{type: "error", error: error}, topic, conn)

  defp reply(data, topic, conn) when is_binary(data),
    do: Gnat.pub(conn, topic, data, [])

  defp reply(data, topic, conn) do
    data
    |> Jason.encode!()
    |> reply(topic, conn)
  end

  # Get topic name for subsctiption
  defp topic(),
    do: Application.get_env(:docker, :nats_topic, "Docker")
end
