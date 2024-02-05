defmodule ER.Destinations.Postgres.Server do
  @moduledoc """
  Manages sending events to a Postgres database
  """
  require Logger
  use GenServer
  use ER.Server.Base
  use ER.Horde.Server
  alias ER.Events.Event

  defp cast_value(%DateTime{} = value) do
    "'" <> Flamel.Moment.to_iso8601(value) <> "'"
  end

  defp cast_value(value) when is_map(value) or is_list(value) do
    case Jason.encode(value) do
      {:ok, json} -> "'#{json}'"
      _ -> "null"
    end
  end

  defp cast_value(nil) do
    "null"
  end

  defp cast_value(value) when is_number(value) do
    Flamel.to_string(value)
  end

  defp cast_value(value) do
    "'#{value}'"
  end

  @extra_fields_to_drop [:context_json, :data_json, :data_schema_json, :durable]

  def messages_to_sql(table_name, messages) do
    fields =
      List.first(messages)
      |> then(fn %{data: event} ->
        Event.to_map(event, @extra_fields_to_drop) |> Map.keys()
      end)

    values =
      messages
      |> Enum.reduce("", fn %{data: event}, acc ->
        data = Event.to_map(event, @extra_fields_to_drop)
        acc = acc <> "("

        acc =
          Enum.reduce(fields, acc, fn field, acc ->
            acc <> cast_value(data[field]) <> ", "
          end)
          |> String.trim(", ")

        acc <> "),"
      end)
      |> String.trim(",")

    # columns = Enum.map_join(fields, ", ", &Flamel.to_string(&1))
    columns =
      Enum.map_join(fields, ", ", fn
        :offset = field -> "\"" <> Flamel.to_string(field) <> "\""
        field -> Flamel.to_string(field)
      end)

    "INSERT INTO #{table_name} (#{columns}) VALUES #{values}"
  end

  def insert(id, messages) do
    GenServer.call(via(id), {:insert, messages})
  end

  def reset(id) do
    GenServer.call(via(id), :reset)
  end

  def handle_continue(:load_state, %{"id" => id} = state) do
    destination = ER.Destinations.get_destination!(id)

    state =
      state
      |> Map.put(:destination, destination)
      |> Map.put(:table_name, destination.config["table_name"])

    Logger.debug("Postgres server started for destination=#{inspect(id)}")

    %{
      "hostname" => hostname,
      "database" => database,
      "username" => username,
      "password" => password,
      "port" => port
    } = destination.config

    state =
      case Postgrex.start_link(
             hostname: hostname,
             database: database,
             username: username,
             password: password,
             port: port,
             pool_size: 20
           ) do
        {:ok, pid} ->
          Map.put(state, :pid, pid)

        error ->
          Logger.error("#{__MODULE__}.handle_continue error=#{inspect(error)}")
          state
      end

    {:noreply, state}
  end

  def handle_call(
        {:insert, messages},
        _from,
        %{pid: pid, table_name: table_name} = state
      ) do
    sql = messages_to_sql(table_name, messages)
    result = Postgrex.query(pid, sql, [])

    {:reply, result, state}
  end

  def handle_call(
        :reset,
        _from,
        %{pid: pid, table_name: table_name} = state
      ) do
    result = Postgrex.query(pid, "TRUNCATE #{table_name}", [])

    {:reply, result, state}
  end

  def handle_terminate(reason, state) do
    Logger.debug("Postgres server terminated: #{inspect(reason)}")
    Logger.debug("Postgres server state: #{inspect(state)}")
    :ok
  end

  @spec name(binary()) :: binary()
  def name(id) do
    "postgres:" <> id
  end
end
