defimpl Bosun.Policy, for: ERWeb.Grpc.Eventrelay.PublishEventsRequest do
  alias Bosun.Context
  alias ER.Accounts.ApiKey

  def permitted?(_resource, _action, %ApiKey{type: :admin}, context, _options) do
    Context.permit(context, "Admins are allowed to do anything")
  end

  def permitted?(_resource, _action, %ApiKey{type: :producer}, context, _options) do
    Context.permit(context, "Producers are allowed to publish events")
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

  def permitted?(_resource, _action, %ApiKey{type: :consumer}, context, _options) do
    Context.permit(context, "Consumers are allowed to consume events")
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

defimpl Bosun.Policy, for: ERWeb.Grpc.Eventrelay.AddSubscriptionToApiKeyRequest do
  alias Bosun.Context
  alias ER.Accounts.ApiKey

  def permitted?(_resource, _action, %ApiKey{type: :admin}, context, _options) do
    Context.permit(context, "Admins are allowed to do anything")
  end

  def permitted?(_resource, _action, _api_key, context, _options) do
    Context.deny(context, "Not permitted")
  end
end

defimpl Bosun.Policy, for: ERWeb.Grpc.Eventrelay.DeleteSubscriptionFromApiKeyRequest do
  alias Bosun.Context
  alias ER.Accounts.ApiKey

  def permitted?(_resource, _action, %ApiKey{type: :admin}, context, _options) do
    Context.permit(context, "Admins are allowed to do anything")
  end

  def permitted?(_resource, _action, _api_key, context, _options) do
    Context.deny(context, "Not permitted")
  end
end
