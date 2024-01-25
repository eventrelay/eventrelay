defmodule ER.Transformers.LiquidTransformer do
  require Logger
  alias ER.Transformers.Transformer

  defstruct transformer: nil

  defimpl ER.Transformers.Transformation do
    def perform(%{transformer: transformer} = transformation, variables) do
      variables = Enum.into(variables, %{})

      try do
        context = Liquex.Context.new(variables, filter_module: ER.Liquid.Filters)

        transformer
        |> fetch_template_ast()
        |> Liquex.render!(context)
        |> then(fn {result, _} ->
          result
          |> to_string()
          |> Jason.decode!()
        end)
      rescue
        e ->
          Logger.error(
            "#{__MODULE__}.perform(#{inspect(transformation)}, #{inspect(variables)}) failed with exception=#{inspect(e)}"
          )

          nil
      end
    end

    defp fetch_template_ast(%Transformer{script: template} = transformer) do
      cache_key = cache_key(transformer)

      if template_ast = ER.Cache.get(cache_key) do
        template_ast
      else
        {:ok, template_ast} = Liquex.parse(template)
        ER.Cache.put(cache_key, template_ast)
        template_ast
      end
    end

    defp cache_key(%Transformer{id: id}) do
      "transformer:template_ast:#{id}"
    end
  end
end
