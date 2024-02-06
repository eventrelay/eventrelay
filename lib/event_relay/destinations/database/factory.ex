defmodule ER.Destinations.Database.Factory do
  def build(%{config: %{"database" => "postgres"}} = destination) do
    %ER.Destinations.Database.Postgres{destination: destination}
  end

  def build(_) do
    nil
  end
end
