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

  def ignore(nick) do
    GenServer.call(__MODULE__, {:ignore, nick})
  end

  def unignore(nick) do
    GenServer.call(__MODULE__, {:unignore, nick})
  end
end
