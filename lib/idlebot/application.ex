defmodule IdleBot.Application do
  @moduledoc false

  use Application
  alias Rustic.Result

  @impl true
  def start(_type, _args) do
    client = ExIRC.start_link!() |> Result.unwrap!()

    children = [
      {IdleBot.QuoteDB, []},
      {IdleBot.Handler, client}
    ]

    opts = [strategy: :one_for_one, name: IdleBot.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
