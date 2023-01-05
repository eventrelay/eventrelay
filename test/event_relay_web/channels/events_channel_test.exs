defmodule ERWeb.EventsChannelTest do
  use ERWeb.ChannelCase

  setup do
    {:ok, _, socket} =
      ERWeb.UserSocket
      |> socket("user_id", %{some: :assign})
      |> subscribe_and_join(ERWeb.EventsChannel, "events:subscription_id")

    %{socket: socket}
  end
end
