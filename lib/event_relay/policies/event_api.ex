defimpl Bosun.Policy, for: ER.Events.Event do
  alias Bosun.Context
  alias ER.Accounts.ApiKey

  def permitted?(_resource, _action, %ApiKey{type: :admin}, context, _options) do
    Context.permit(context, "Admins are allowed to do anything")
  end

  def permitted?(
        _resource,
        :publish_events,
        %ApiKey{type: :producer} = api_key,
        context,
        topic_name: topic_name
      ) do
    if ApiKey.allowed_topic?(api_key, topic_name) do
      Context.permit(context, "Producers are allowed to publish events")
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
