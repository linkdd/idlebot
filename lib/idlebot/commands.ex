defmodule IdleBot.Commands do
  @moduledoc false

  alias IdleBot.Handler.State

  def dispatch("ping") do
    continuation = fn sender, channel, %State{} = state ->
      ExIRC.Client.msg(state.client, :privmsg, channel, "#{sender.nick}: pong")
      :ok
    end
    {:ok, continuation}
  end
  def dispatch(cmd) do
    {:error, :unknown_command}
  end
end
