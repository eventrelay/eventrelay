defprotocol ER.Transformers.Transformation do
  @spec perform(term(), map()) :: map() | nil
  def perform(t, v)
end
