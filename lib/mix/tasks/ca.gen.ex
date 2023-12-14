defmodule Mix.Tasks.Ca.Gen do
  @moduledoc """
  The organization mix task: 
  ## Examples
    $ mix ca.gen --name "EventRelay" 
  """
  use Mix.Task
  import Mix.Generator

  @default_output "priv/tls/"
  @default_name "EventRelay"
  @default_force false

  @shortdoc "Generates a certificate authority"

  @switches [
    name: :string,
    force: :boolean,
    output: :string
  ]

  @aliases []

  def run(all_args) do
    {opts, _args} = OptionParser.parse!(all_args, strict: @switches, aliases: @aliases)
    name = opts[:name] || @default_name
    output = opts[:output] || @default_output
    force = opts[:force] || @default_force

    filename = String.downcase(name) |> String.replace(" ", "_")

    keyfile = output <> filename <> "_key.pem"
    crtfile = output <> filename <> ".pem"

    {key, crt} = ER.CA.create(name)
    create_file(keyfile, key, force: force)
    create_file(crtfile, crt, force: force)

    Mix.shell().info("""
      Files generated:

      cacertfile: #{crtfile}
      cakeyfile: #{keyfile}
    """)
  end
end
