defimpl Bosun.Policy, for: Any do
  alias Bosun.Context

  def permitted?(_resource, _action, _subject, context, _options) do
    Context.deny(context, "Not permitted")
  end
end
