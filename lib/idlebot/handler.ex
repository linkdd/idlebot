defmodule IdleBot.Handler do
  @moduledoc false

  use GenServer
  require Logger
  alias Rustic.Result

  defmodule State do
    @moduledoc false

    defstruct [
      :host,
      :port,
      :pass,
      :nick,
      :user,
      :name,
      :tls,
      :client,
      :channels,
      :ignored
    ]
  end

  def start_link(client) do
    state = %State{
      host: Application.fetch_env!(:idlebot, :host),
      port: Application.fetch_env!(:idlebot, :port),
      pass: Application.fetch_env!(:idlebot, :password),
      nick: Application.fetch_env!(:idlebot, :nick),
      user: Application.fetch_env!(:idlebot, :user),
      name: Application.fetch_env!(:idlebot, :name),
      tls: Application.fetch_env!(:idlebot, :tls),
      client: client,
      channels: [],
      ignored: []
    }
    GenServer.start_link(__MODULE__, state, name: IdleBot)
  end

  @impl true
  def init(%State{} = state) do
    ExIRC.Client.add_handler(state.client, self())
    result = case state.tls do
      true -> ExIRC.Client.connect_ssl!(state.client, state.host, state.port)
      false -> ExIRC.Client.connect!(state.client, state.host, state.port)
    end

    result |> Result.map(fn nil -> state end)
  end

  @impl true
  def terminate(reason, state) do
    Logger.info("Terminating", reason: reason)

    ExIRC.Client.quit(state.client, "Terminated")

    :ok
  end

  @impl true
  def handle_call({:join, channel, password}, _from, %State{} = state) do
    result = ExIRC.Client.join(state.client, channel, password)

    {:reply, result, %State{state | channels: [channel | state.channels]}}
  end
  def handle_call({:leave, channel}, _from, %State{} = state) do
    result = ExIRC.Client.part(state.client, channel)

    channels = state.channels |> List.delete(channel)
    {:reply, result, %State{state | channels: channels}}
  end
  def handle_call({:say, dest, msg}, _from, %State{} = state) do
    result = ExIRC.Client.msg(state.client, :privmsg, dest, msg)
    {:reply, result, state}
  end
  def handle_call({:ignore, nick}, _from, %State{} = state) do
    {:reply, :ok, %State{state | ignored: [nick | state.ignored]}}
  end
  def handle_call({:unignore, nick}, _from, %State{} = state) do
    ignored = state.ignored |> List.delete(nick)
    {:reply, :ok, %State{state | ignored: ignored}}
  end

  @impl true
  def handle_info({:connected, server, port}, %State{} = state) do
    Logger.info("Connected to server", server: server, port: port)

    ExIRC.Client.logon(state.client, state.pass, state.nick, state.user, state.name)
      |> Result.or_else(fn reason ->
        Logger.error("Could not login to server as #{state.user}", reason: reason)
      end)
      |> Result.unwrap!()

    {:noreply, state}
  end
  def handle_info(:logged_in, %State{} = state) do
    Logger.info("Successfully logged in to server")
    {:noreply, state}
  end
  def handle_info({:login_failed, :nick_in_use}, %State{} = state) do
    nick = Enum.map(1..8, fn _ -> Enum.random('abcdefghijklmnopqrstuvwxyz') end)
      |> to_string()

    ExIRC.Client.nick(state.client, nick)
    {:noreply, state}
  end
  def handle_info(:disconnected, %State{} = state) do
    Logger.info("Disconnected from server")
    {:stop, :normal, state}
  end
  def handle_info({:received, "!" <> command, sender, channel}, %State{} = state) do
    if not Enum.member?(state.ignored, sender.nick) do
      command
        |> String.split()
        |> IdleBot.Commands.dispatch()
        |> Result.and_then(fn continuation -> continuation.(sender, channel, state) end)
        |> Result.or_else(fn reason -> send_error(reason, channel, state) end)
        |> Result.unwrap!()
    end

    {:noreply, state}
  end
  def handle_info({:received, msg, sender, channel}, %State{} = state) do
    if not Enum.member?(state.ignored, sender.nick) do
      IdleBot.Utils.get_links_from_message(msg)
        |> Enum.map(fn link -> send_to({channel, link}, state) end)
    end

    {:noreply, state}
  end
  def handle_info({:received, msg, sender}, %State{} = state) do
    if not Enum.member?(state.ignored, sender.nick) do
      IdleBot.Utils.get_links_from_message(msg)
        |> Enum.map(fn link -> send_to({sender.nick, link}, state) end)
    end

    {:noreply, state}
  end
  def handle_info(_msg, %State{} = state) do
    {:noreply, state}
  end

  defp send_to({dest, link}, %State{} = state) do
    ExIRC.Client.msg(state.client, :privmsg, dest, "Title: #{link}")
    :ok
  end

  defp send_error(reason, channel, %State{} = state) do
    ExIRC.Client.msg(state.client, :privmsg, channel, "Error: #{inspect(reason)}")
    :ok
  end
end
