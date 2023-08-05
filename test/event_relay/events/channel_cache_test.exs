defmodule ER.Events.ChannelCacheTest do
  use ER.DataCase

  describe "register_socket/3" do
    test "increases the count for a subscription" do
      fake_pid = spawn(fn -> nil end)
      ER.Events.ChannelCache.register_socket(fake_pid, "test", false)
      assert ER.Events.ChannelCache.get_socket_count("test") == 1
    end
  end

  describe "deregister_socket/1" do
    test "decreases the count for a subscription" do
      fake_pid = spawn(fn -> nil end)
      ER.Events.ChannelCache.register_socket(fake_pid, "deregister", false)
      assert ER.Events.ChannelCache.get_socket_count("deregister") == 1
      ER.Events.ChannelCache.deregister_socket("deregister")
      assert ER.Events.ChannelCache.get_socket_count("deregister") == 0
    end
  end

  describe "any_sockets?/2" do
    test "returns true if there is a subscription" do
      fake_pid = spawn(fn -> nil end)
      ER.Events.ChannelCache.register_socket(fake_pid, "any_true", false)

      assert ER.Events.ChannelCache.any_sockets?("any_true") == true
    end

    test "returns false if there is a subscription" do
      assert ER.Events.ChannelCache.any_sockets?("any_false") == false
    end
  end
end
