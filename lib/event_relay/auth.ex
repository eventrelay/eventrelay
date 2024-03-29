defmodule ER.Auth do
  @key_size 42
  @secret_size 64

  def generate_key() do
    :crypto.strong_rand_bytes(@key_size)
    |> Base.url_encode64()
    |> binary_part(0, @key_size)
  end

  def generate_secret() do
    :crypto.strong_rand_bytes(@secret_size)
    |> Base.url_encode64()
    |> binary_part(0, @secret_size)
  end

  def hmac(value: value, signing_secret: signing_secret)
      when is_nil(value) or is_nil(signing_secret) do
    ""
  end

  def hmac(value: value, signing_secret: signing_secret) do
    :crypto.mac(:hmac, :sha256, signing_secret, value)
    |> Base.encode16()
    |> String.downcase()
  end
end
