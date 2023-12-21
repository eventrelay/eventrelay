defmodule ERWeb.LiveViewHelpers do
  alias ER.Repo

  def api_key_has_topic?(api_key, topic) do
    api_key = Repo.preload(api_key, :topics)
    api_key_topics = Enum.map(api_key.topics, & &1.id)
    topic.id in api_key_topics
  end

  def api_key_has_subscription?(api_key, subscription) do
    api_key = Repo.preload(api_key, :subscriptions)
    api_key_subscriptions = Enum.map(api_key.subscriptions, & &1.id)
    subscription.id in api_key_subscriptions
  end

  def topics_to_select_options(topics) do
    Enum.map(topics, fn topic -> {topic.name, topic.name} end)
  end
end
