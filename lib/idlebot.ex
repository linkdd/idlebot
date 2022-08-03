defmodule IdleBot do
  @moduledoc false

  def join(channel, password \\ "") do
    GenServer.call(__MODULE__, {:join, channel, password})
  end

  def leave(channel) do
    GenServer.call(__MODULE__, {:leave, channel})
  end

  def say(dest, msg) do
    GenServer.call(__MODULE__, {:say, dest, msg})
  end
end
