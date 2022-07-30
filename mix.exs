defmodule IdleBot.MixProject do
  use Mix.Project

  def project do
    [
      app: :idlebot,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [
        idlebot: [
          applications: [
            idlebot: :permanent
          ]
        ]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger, :exirc],
      mod: {IdleBot.Application, []}
    ]
  end

  defp deps do
    [
      {:rustic_result, "~> 0.6"},
      {:exirc, "~> 2.0"},
      {:httpoison, "~> 1.8"},
      {:floki, "~> 0.33"}
    ]
  end
end
