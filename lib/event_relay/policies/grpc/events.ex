defimpl Bosun.Policy, for: ERWeb.Grpc.Eventrelay.PublishEventsRequest do
  alias Bosun.Context
  alias ER.Accounts.ApiKey

  def permitted?(_resource, _action, %ApiKey{type: :admin}, context, _options) do
    Context.permit(context, "Admins are allowed to do anything")
  end

  def permitted?(resource, _action, %ApiKey{type: :producer} = api_key, context, _options) do
    {topic_name, _topic_identifier} = ER.Events.Topic.parse_topic(resource.topic)

    if ApiKey.allowed_topic?(api_key, topic_name) do
      Context.permit(
        context,
        "Producers are allowed to publish events for topic_name=#{topic_name}"
      )
    else
      Context.deny(
        context,
        "ApiKey with id=#{api_key.id} is not associated with topic_name=#{topic_name}"
      )
    end
  end

  def permitted?(_resource, _action, _api_key, context, _options) do
    Context.deny(context, "Not permitted")
  end
end

defimpl Bosun.Policy, for: ERWeb.Grpc.Eventrelay.PullEventsRequest do
  alias Bosun.Context
  alias ER.Accounts.ApiKey

  def permitted?(_resource, _action, %ApiKey{type: :admin}, context, _options) do
    Context.permit(context, "Admins are allowed to do anything")
  end

  def permitted?(resource, _action, %ApiKey{type: :consumer} = api_key, context, _options) do
    {topic_name, _topic_identifier} = ER.Events.Topic.parse_topic(resource.topic)

    if ApiKey.allowed_destination?(api_key, topic_name) do
      Context.permit(
        context,
        "Consumers are allowed to consume events for topic_name=#{topic_name}"
      )
    else
      Context.deny(
        context,
        "ApiKey with id=#{api_key.id} is not associated with topic_name=#{topic_name} via a destination"
      )
    end
  end

  def permitted?(_resource, _action, _api_key, context, _options) do
    Context.deny(context, "Not permitted")
  end
end

defimpl Bosun.Policy, for: ERWeb.Grpc.Eventrelay.PullQueuedEventsRequest do
  alias Bosun.Context
  alias ER.Accounts.ApiKey

  def permitted?(_resource, _action, %ApiKey{type: :admin}, context, _options) do
    Context.permit(context, "Admins are allowed to do anything")
  end

  def permitted?(resource, _action, %ApiKey{type: :consumer} = api_key, context, _options) do
    destination = ER.Destinations.get_destination!(resource.destination_id)
    topic_name = destination.topic_name

    if ApiKey.allowed_destination?(api_key, topic_name) do
      Context.permit(
        context,
        "Consumers are allowed to consume events for topic_name=#{topic_name}"
      )
    else
      Context.deny(
        context,
        "ApiKey with id=#{api_key.id} is not associated with topic_name=#{topic_name} via a destination"
      )
    end
  end

  def permitted?(_resource, _action, _api_key, context, _options) do
    Context.deny(context, "Not permitted")
  end
end
