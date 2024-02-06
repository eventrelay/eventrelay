defmodule ER.Destinations.Database.Postgres do
  defstruct destination: nil

  defimpl ER.Destinations.Database do
    def prepare_for_start(%{destination: destination} = postgres) do
      ER.Destinations.Database.Postgres.Server.factory(destination.id)
      postgres
    end

    def insert(%{destination: destination}, messages) do
      ER.Destinations.Database.Postgres.Server.factory(destination.id)

      case ER.Destinations.Database.Postgres.Server.insert(destination.id, messages) do
        {:ok, _} ->
          messages

        _ ->
          messages
      end
    end
  end
end
