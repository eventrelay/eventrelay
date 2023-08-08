defmodule ER.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ER.Accounts` context.
  """

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: valid_user_password()
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> ER.Accounts.register_user()

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  @doc """
  Generate a api_key.
  """
  def api_key_fixture(attrs \\ %{}) do
    {:ok, api_key} =
      attrs
      |> Enum.into(%{
        key: "some key",
        secret: "some secret",
        status: :active,
        type: :admin
      })
      |> ER.Accounts.create_api_key()

    api_key
  end
end
