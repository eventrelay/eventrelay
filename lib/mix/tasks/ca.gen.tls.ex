defmodule Mix.Tasks.Ca.Gen.Tls do
  @moduledoc """
  The organization mix task: 
  ## Examples
    $ mix ca.gen.tls --name "Server" --alt_names "localhost"
  """
  use Mix.Task
  import Mix.Generator

  @default_output "priv/tls/"
  @default_name "EventRelay"
  @default_force false
  @default_alt_names "localhost"
  @default_ca_crt "priv/tls/eventrelay.pem"
  @default_ca_key "priv/tls/eventrelay_key.pem"

  @shortdoc "Generate a TLS key and certificate based on EventRelay's Certificate Authority"

  @switches [
    name: :string,
    force: :boolean,
    output: :string,
    alt_names: :string,
    ca_crt: :string,
    ca_key: :string
  ]

  @aliases []

  def run(all_args) do
    {opts, _args} = OptionParser.parse!(all_args, strict: @switches, aliases: @aliases)
    name = opts[:name] || @default_name
    output = opts[:output] || @default_output
    force = opts[:force] || @default_force
    ca_key = opts[:ca_key] || @default_ca_key
    ca_crt = opts[:ca_crt] || @default_ca_crt

    alt_names =
      (opts[:alt_names] || @default_alt_names) |> String.split(",") |> Enum.map(&String.trim/1)

    filename = String.downcase(name) |> String.replace(" ", "_")

    keyfile = output <> filename <> "_key.pem"
    crtfile = output <> filename <> ".pem"

    ca_key_pem = File.read!(ca_key)
    ca_crt_pem = File.read!(ca_crt)

    {key, crt} =
      ER.CA.generate_key_and_crt(name, alt_names, ca_key_pem, ca_crt_pem)

    create_file(keyfile, key, force: force)
    create_file(crtfile, crt, force: force)

    Mix.shell().info("""
      Files generated:

      cacertfile: #{crtfile}
      cakeyfile: #{keyfile}
    """)
  end
end
