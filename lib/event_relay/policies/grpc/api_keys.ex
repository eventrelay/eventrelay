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
