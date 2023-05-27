defmodule Help do
  defmacro __using__(_opts) do
    quote do
      import Ecto.Query
      alias ER.Repo
      alias ER.Events.{Event, Topic}
      alias ER.Accounts
      alias ER.Accounts.{ApiKey, ApiKeyTopic, ApiKeySubscription}

      :ok
    end
  end
end
