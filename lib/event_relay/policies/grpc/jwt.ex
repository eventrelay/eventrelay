defimpl Bosun.Policy, for: ERWeb.Grpc.Eventrelay.CreateJWTRequest do
  alias Bosun.Context

  def permitted?(_resource, _action, _api_key, context, _options) do
    Context.permit(context, "Permitted")
  end
end
