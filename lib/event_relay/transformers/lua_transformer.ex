defmodule ER.Transformers.LuaTransformer do
  require Logger

  defstruct transformer: nil

  def return(nil, _) do
    nil
  end

  def return(data, %{return_type: :map}) do
    to_map(data)
  end

  def return(data, _) do
    data
  end

  def debug(thing, label) do
    if ER.Env.debug_transformers() do
      Logger.debug("#{__MODULE__} debugging transformer with #{inspect(label)}:#{inspect(thing)}")
    end

    thing
  end

  def to_map(list, acc \\ %{})

  def to_map([head | rest], acc) do
    acc =
      case head do
        # we have a nested map
        {key, [{_, _} | _] = t} ->
          Map.put(acc, key, to_map(t))

        {key, val} ->
          Map.put(acc, key, val)

        # ignoring this val
        unexpected ->
          Logger.debug("ER.Transformers.GooglePubsub.to_map unexpected=#{inspect(unexpected)}")
          acc
      end

    to_map(rest, acc)
  end

  def to_map([], acc) do
    acc
  end

  defimpl ER.Transformers.Transformation do
    alias ER.Transformers.LuaTransformer, as: Transformer

    def perform(%{transformer: %{script: script} = transformer} = _transformation, variables) do
      script
      |> ER.Lua.eval(variables)
      |> Transformer.debug(:pre_return)
      |> Transformer.return(transformer)
      |> Transformer.debug(:post_return)
    end
  end
end
