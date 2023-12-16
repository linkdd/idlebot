defmodule IdleBot.QuoteDB do
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

  def get_random(channel, patterns \\ []) do
    GenServer.call(__MODULE__, {:get_random, channel, patterns})
  end

  def add(channel, author, text) do
    GenServer.call(__MODULE__, {:add, channel, author, text})
  end

  @impl true
  def init(%State{} = state) do
    state = %{state | table_id: ETS.new(:idlebot_quotedb, [:set])}

    File.read(state.file_path)
      |> Result.and_then(fn content -> Jason.decode(content) end)
      |> Result.and_then(fn data ->
        data |> Enum.each(fn {channel, quotes} ->
          quotes = quotes |> Enum.map(fn %{"author" => author, "text" => text} -> {author, text} end)
          ETS.insert(state.table_id, {channel, quotes})
        end)

        {:ok, state}
      end)
  end

  @impl true
  def handle_call({:get_random, channel, patterns}, _from, %State{} = state) do
    reply = case ETS.lookup(state.table_id, channel) do
      [] -> :none
      [{_, []}] -> :none
      [{_, quotes}] ->
        try do
          {:some, quotes |> filter_quotes(patterns) |> Enum.random()}
        rescue
          Enum.EmptyError -> :none
        end
    end

    {:reply, reply, state}
  end
  def handle_call({:add, channel, author, text}, _from, %State{} = state) do
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
        quotes = quotes |> Enum.map(fn {author, text} ->
          %{
            "author" => author,
            "text" => text
          }
        end)
        acc |> Map.put(channel, quotes)
      end,
      %{},
      state.table_id
    )

    Jason.encode(data)
      |> Result.and_then(fn content -> File.write(state.file_path, content) end)
      |> Result.or_else(fn err ->
        Logger.error("Could not sync quote database: #{err}")
        :ok
      end)
      |> Result.unwrap!()

    {:noreply, state}
  end

  defp filter_quotes([], _), do: []
  defp filter_quotes(quotes, []), do: quotes
  defp filter_quotes(quotes, [pattern | patterns]) do
    quotes
      |> Seqfuzz.filter(pattern, &(elem(&1, 1)))
      |> filter_quotes(patterns)
  end
end
