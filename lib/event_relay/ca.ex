defmodule ER.CA do
  require Logger

  def generate_key_and_crt(
        name,
        alt_names \\ ["localhost"],
        ca_key_pem \\ System.get_env("ER_CA_KEY"),
        ca_crt_pem \\ System.get_env("ER_CA_CRT")
      ) do
    ca_key = X509.PrivateKey.from_pem!(ca_key_pem)
    ca = X509.Certificate.from_pem!(ca_crt_pem)
    key = X509.PrivateKey.new_rsa(4096)

    cert =
      key
      |> X509.PublicKey.derive()
      |> X509.Certificate.new(
        "/C=US/ST=FL/L=Orlando/O=EventRelay/CN=#{name}",
        ca,
        ca_key,
        extensions: [
          subject_alt_name: X509.Certificate.Extension.subject_alt_name(alt_names)
        ]
      )

    {X509.PrivateKey.to_pem(key), X509.Certificate.to_pem(cert)}
  end

  def create(name \\ "EventRelay") do
    key = X509.PrivateKey.new_rsa(4096)

    ca =
      X509.Certificate.self_signed(
        key,
        "/C=US/ST=FL/L=Orlando/O=EventRelay/CN=#{name} Root CA",
        template: :root_ca
      )

    {X509.PrivateKey.to_pem(key), X509.Certificate.to_pem(ca)}
  end

  def to_der(pem) do
    {type, entry} =
      pem
      |> decode_pem_bin()
      |> decode_pem_entry()
      |> split_type_and_entry()

    {type, encode_der(type, entry)}
  end

  defp decode_pem_bin(pem_bin) do
    pem_bin |> :public_key.pem_decode() |> hd()
  end

  defp decode_pem_entry(pem_entry) do
    :public_key.pem_entry_decode(pem_entry)
  end

  defp encode_der(ans1_type, ans1_entity) do
    :public_key.der_encode(ans1_type, ans1_entity)
  end

  defp split_type_and_entry(ans1_entry) do
    ans1_type = elem(ans1_entry, 0)
    {ans1_type, ans1_entry}
  end
end
