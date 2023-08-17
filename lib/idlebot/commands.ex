defmodule IdleBot.Commands do
  @moduledoc false

  alias IdleBot.Handler.State

  def dispatch(["ping" | _]) do
    continuation = fn sender, channel, %State{} = state ->
      ExIRC.Client.msg(state.client, :privmsg, channel, "#{sender.nick}: pong")
      :ok
    end
    {:ok, continuation}
  end
  def dispatch(["google" | search_terms]) do
    qs = %{"q" => search_terms |> Enum.join(" ")} |> URI.encode_query()
    url = "https://letmegooglethat.com/?#{qs}"

    continuation = fn sender, channel, %State{} = state ->
      ExIRC.Client.msg(state.client, :privmsg, channel, url)
      :ok
    end
    {:ok, continuation}
  end
  def dispatch(cmd) do
    {:error, :unknown_command}
  end
end
