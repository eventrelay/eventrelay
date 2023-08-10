defmodule Help do
  defmacro __using__(_opts) do
    quote do
      import Ecto.Query
      import Ecto.Changeset
      alias ER.Repo
      alias ER.Events.{Event, Topic}
      alias ER.Accounts
      alias ER.Accounts.{ApiKey, ApiKeyTopic, ApiKeySubscription}
      alias ER.Ingestors.Ingestor
      alias ER.Transformers.Transformer

      :ok
    end
  end
end
