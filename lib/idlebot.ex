defmodule IdleBot do
  @moduledoc false

  def join(channel, password \\ nil) do
    GenServer.call(__MODULE__, {:join, channel, password})
  end

  def leave(channel) do
    GenServer.call(__MODULE__, {:leave, channel})
  end
end
