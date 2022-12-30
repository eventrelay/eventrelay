defmodule ER.Subscriptions.Server do
  @moduledoc """
  Manages the subscriptions
  """
  require Logger
  use GenServer
  use ER.Server

  def handle_continue(:load_state, state) do
    schedule_next_tick()
    state = %{state | status: :running}
    {:noreply, state}
  end

  @spec reset(binary()) :: any
  def reset(id) do
    GenServer.cast(via(id), {:reset})
  end

  @spec status(binary(), binary(), keyword()) :: map()
  def status(id, _, _opts \\ []) do
    GenServer.call(via(id), {:get_status})
  end

  def handle_cast({:reset}, state) do
    {:noreply, state}
  end

  def handle_call({:get_status}, _, %{status: status} = state) do
    {:reply, status, state}
  end

  def handle_info(:tick, state) do
    {:noreply, state}
  end

  @spec name(binary()) :: binary()
  def name(id) do
    "subscription:" <> id
  end
end
