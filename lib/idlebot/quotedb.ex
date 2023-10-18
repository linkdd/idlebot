defmodule IdleBot.QuotDB do
  @moduledoc false

  use GenServer
  require Logger
  alias :ets, as: ETS
  alias Rustic.Result

  defmodule State do
    @moduledoc false

    defstruct [
      :table_id,
      :file_path
    ]
  end

  def start_link([]) do
    state = %State{
      table_id: nil,
      file_path: Application.fetch_env!(:idlebot, :quotedb_path),
    }
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def get_random(channel) do
    GenServer.call(__MODULE__, {:get_random, channel})
  end

  def add(channel, author, text) do
    GenServer.call(__MODULE__, {:add, channel, author, text})
  end

  @impl true
  def init(%State{} = state) do
    state = %{state | table_id: ETS.new(:idlebot_quotedb, [:set])}

    with
      {:ok, content} <- File.read(state.file_path),
      {:ok, data} <- Jason.decode(content),
    do
      data |> Enum.each(fn {channel, quotes} ->
        ETS.insert(state.table_id, {channel, quotes})
      end)

      {:ok, state}
    end
  end

  @impl true
  def handle_call({:get_random, channel}, _from, %State{} = state) do
    reply = case ETS.lookup(state.table_id, channel) do
      [] -> :none
      [{_, []}] -> :none
      [{_, quotes}] -> {:some, Enum.random(quotes)}
    end

    {:reply, reply, state}
  end
  def handle_call({:add, channel, author, text}, _from, %State = state) do
    quotes = case ETS.lookup(state.table_id, channel) do
      [] -> []
      [{_, quotes}] -> quotes
    end

    ETS.insert(state.table_id, {channel, [{author, text} | quotes]})
    GenServer.cast(__MODULE__, :sync_to_disk)
    {:reply, :ok, state}
  end

  @impl true
  def handle_cast(:sync_to_disk, %State{} = state) do
    data = ETS.foldl(
      fn {channel, quotes}, acc ->
        quotes = quotes |> Enum.each(fn {author, text} -> %{
          "author" => author,
          "text" => text
        })
        acc |> Map.put(channel, quotes)
      end,
      %{},
      state.table_id
    )

    with
      {:ok, content} <- Jason.encode(data),
      :ok <- File.write(state.file_path, content)
    do
      :ok
    else
      err -> Logger.error("Could not sync quote database: #{err}")
    end

    {:noreply, state}
  end
end