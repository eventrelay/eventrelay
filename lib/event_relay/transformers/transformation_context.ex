defprotocol ER.Transformers.TransformationContext do
  @spec build(term()) :: map()
  def build(t)
end
