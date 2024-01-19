defmodule ERWeb.UserLoginLive do
  use ERWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">
        Log in to account
        <:subtitle></:subtitle>
      </.header>

      <.simple_form
        :let={f}
        id="login_form"
        for={%{}}
        as={:user}
        action={~p"/users/log_in"}
        phx-update="ignore"
      >
        <.input field={f[:email]} type="email" label="Email" required />
        <.input field={f[:password]} type="password" label="Password" required />

        <:actions :let={f}>
          <.input field={f[:remember_me]} type="checkbox" label="Keep me logged in" />
          <.link href={~p"/users/reset_password"} class="text-sm font-semibold">
            Forgot your password?
          </.link>
        </:actions>
        <:actions>
          <.button phx-disable-with="Sigining in..." class="w-full">
            Log in <span aria-hidden="true">→</span>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    email = live_flash(socket.assigns.flash, :email)
    {:ok, assign(socket, email: email), temporary_assigns: [email: nil]}
  end
end
