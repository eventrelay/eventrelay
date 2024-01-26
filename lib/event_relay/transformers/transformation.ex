defprotocol ER.Transformers.Transformation do
  @spec perform(term(), map()) :: map() | nil
  def perform(t, v)

  @spec precompile(term()) :: term()
  def precompile(t)

  @spec reset(term()) :: term()
  def reset(t)
end
