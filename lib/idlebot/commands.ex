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
  def dispatch(["quote"]) do
    continuation = fn sender, channel, %State{} = state ->
      msg = case IdleBot.QuoteDB.get_random(channel) do
        :none -> "No quotes for this channel"
        {:some, {author, text}} -> "> #{text} -- #{author}"
      end
      ExIRC.Client.msg(state.client, :privmsg, channel, msg)
      :ok
    end
    {:ok, continuation}
  end
  def dispatch(["quote", "add", author | text]) when length(text) > 0 do
    text = text |> Enum.join(" ")
    continuation = fn sender, channel, %State{} = state ->
      IdleBot.QuoteDB.add(channel, author, text)
      ExIRC.Client.msg(state.client, :privmsg, channel, "#{sender.nick}: Thank you for your contribution")
      :ok
    end
    {:ok, continuation}
  end
  def dispatch(["quote", "search" | patterns]) when length(patterns) > 0 do
    continuation = fn sender, channel, %State{} = state ->
      msg = case IdleBot.QuoteDB.get_random(channel, patterns) do
        :none -> "No quotes found"
        {:some, {author, text}} -> "> #{text} -- #{author}"
      end
      ExIRC.Client.msg(state.client, :privmsg, channel, msg)
      :ok
    end
    {:ok, continuation}
  end
  def dispatch(["quote" | _]) do
    {:error, {
      :invalid_command,
      {:quote, :usage, ["!quote", "quote add <author> <text>", "quote search <text>"]}
    }}
  end
  def dispatch(cmd) do
    {:error, :unknown_command}
  end
end
