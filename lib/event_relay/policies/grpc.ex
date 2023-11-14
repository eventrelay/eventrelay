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

    if ApiKey.allowed_subscription?(api_key, topic_name) do
      Context.permit(
        context,
        "Consumers are allowed to consume events for topic_name=#{topic_name}"
      )
    else
      Context.deny(
        context,
        "ApiKey with id=#{api_key.id} is not associated with topic_name=#{topic_name} via a subscription"
      )
    end
  end

  def permitted?(_resource, _action, _api_key, context, _options) do
    Context.deny(context, "Not permitted")
  end
end

defimpl Bosun.Policy, for: ERWeb.Grpc.Eventrelay.ListTopicsRequest do
  alias Bosun.Context
  alias ER.Accounts.ApiKey

  def permitted?(_resource, _action, %ApiKey{type: :admin}, context, _options) do
    Context.permit(context, "Admins are allowed to do anything")
  end

  def permitted?(_resource, _action, _api_key, context, _options) do
    Context.deny(context, "Not permitted")
  end
end

defimpl Bosun.Policy, for: ERWeb.Grpc.Eventrelay.CreateTopicRequest do
  alias Bosun.Context
  alias ER.Accounts.ApiKey

  def permitted?(_resource, _action, %ApiKey{type: :admin}, context, _options) do
    Context.permit(context, "Admins are allowed to do anything")
  end

  def permitted?(_resource, _action, _api_key, context, _options) do
    Context.deny(context, "Not permitted")
  end
end

defimpl Bosun.Policy, for: ERWeb.Grpc.Eventrelay.DeleteTopicRequest do
  alias Bosun.Context
  alias ER.Accounts.ApiKey

  def permitted?(_resource, _action, %ApiKey{type: :admin}, context, _options) do
    Context.permit(context, "Admins are allowed to do anything")
  end

  def permitted?(_resource, _action, _api_key, context, _options) do
    Context.deny(context, "Not permitted")
  end
end

defimpl Bosun.Policy, for: ERWeb.Grpc.Eventrelay.ListSubscriptionsRequest do
  alias Bosun.Context
  alias ER.Accounts.ApiKey

  def permitted?(_resource, _action, %ApiKey{type: :admin}, context, _options) do
    Context.permit(context, "Admins are allowed to do anything")
  end

  def permitted?(_resource, _action, _api_key, context, _options) do
    Context.deny(context, "Not permitted")
  end
end

defimpl Bosun.Policy, for: ERWeb.Grpc.Eventrelay.GetSubscriptionRequest do
  alias Bosun.Context
  alias ER.Accounts.ApiKey

  def permitted?(_resource, _action, %ApiKey{type: :admin}, context, _options) do
    Context.permit(context, "Admins are allowed to do anything")
  end

  def permitted?(_resource, _action, _api_key, context, _options) do
    Context.deny(context, "Not permitted")
  end
end

defimpl Bosun.Policy, for: ERWeb.Grpc.Eventrelay.CreateSubscriptionRequest do
  alias Bosun.Context
  alias ER.Accounts.ApiKey

  def permitted?(_resource, _action, %ApiKey{type: :admin}, context, _options) do
    Context.permit(context, "Admins are allowed to do anything")
  end

  def permitted?(_resource, _action, _api_key, context, _options) do
    Context.deny(context, "Not permitted")
  end
end

defimpl Bosun.Policy, for: ERWeb.Grpc.Eventrelay.DeleteSubscriptionRequest do
  alias Bosun.Context
  alias ER.Accounts.ApiKey

  def permitted?(_resource, _action, %ApiKey{type: :admin}, context, _options) do
    Context.permit(context, "Admins are allowed to do anything")
  end

  def permitted?(_resource, _action, _api_key, context, _options) do
    Context.deny(context, "Not permitted")
  end
end

defimpl Bosun.Policy, for: ERWeb.Grpc.Eventrelay.CreateApiKeyRequest do
  alias Bosun.Context
  alias ER.Accounts.ApiKey

  def permitted?(_resource, _action, %ApiKey{type: :admin}, context, _options) do
    Context.permit(context, "Admins are allowed to do anything")
  end

  def permitted?(_resource, _action, _api_key, context, _options) do
    Context.deny(context, "Not permitted")
  end
end

defimpl Bosun.Policy, for: ERWeb.Grpc.Eventrelay.RevokeApiKeyRequest do
  alias Bosun.Context
  alias ER.Accounts.ApiKey

  def permitted?(_resource, _action, %ApiKey{type: :admin}, context, _options) do
    Context.permit(context, "Admins are allowed to do anything")
  end

  def permitted?(_resource, _action, _api_key, context, _options) do
    Context.deny(context, "Not permitted")
  end
end

defimpl Bosun.Policy, for: ERWeb.Grpc.Eventrelay.AddSubscriptionsToApiKeyRequest do
  alias Bosun.Context
  alias ER.Accounts.ApiKey

  def permitted?(_resource, _action, %ApiKey{type: :admin}, context, _options) do
    Context.permit(context, "Admins are allowed to do anything")
  end

  def permitted?(_resource, _action, _api_key, context, _options) do
    Context.deny(context, "Not permitted")
  end
end

defimpl Bosun.Policy, for: ERWeb.Grpc.Eventrelay.DeleteSubscriptionsFromApiKeyRequest do
  alias Bosun.Context
  alias ER.Accounts.ApiKey

  def permitted?(_resource, _action, %ApiKey{type: :admin}, context, _options) do
    Context.permit(context, "Admins are allowed to do anything")
  end

  def permitted?(_resource, _action, _api_key, context, _options) do
    Context.deny(context, "Not permitted")
  end
end

defimpl Bosun.Policy, for: ERWeb.Grpc.Eventrelay.AddTopicsToApiKeyRequest do
  alias Bosun.Context
  alias ER.Accounts.ApiKey

  def permitted?(_resource, _action, %ApiKey{type: :admin}, context, _options) do
    Context.permit(context, "Admins are allowed to do anything")
  end

  def permitted?(_resource, _action, _api_key, context, _options) do
    Context.deny(context, "Not permitted")
  end
end

defimpl Bosun.Policy, for: ERWeb.Grpc.Eventrelay.DeleteTopicsFromApiKeyRequest do
  alias Bosun.Context
  alias ER.Accounts.ApiKey

  def permitted?(_resource, _action, %ApiKey{type: :admin}, context, _options) do
    Context.permit(context, "Admins are allowed to do anything")
  end

  def permitted?(_resource, _action, _api_key, context, _options) do
    Context.deny(context, "Not permitted")
  end
end

defimpl Bosun.Policy, for: ERWeb.Grpc.Eventrelay.CreateJWTRequest do
  alias Bosun.Context

  def permitted?(_resource, _action, _api_key, context, _options) do
    Context.permit(context, "Permitted")
  end
end
