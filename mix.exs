defmodule IdleBot.MixProject do
  use Mix.Project

  def project do
    [
      app: :idlebot,
      version: "0.4.1",
      elixir: "~> 1.15",
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
      {:httpoison, "~> 2.1"},
      {:floki, "~> 0.35"},
      {:jason, "~> 1.4"},
      {:seqfuzz, "~> 0.2"},
    ]
  end
end
