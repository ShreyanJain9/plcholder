defmodule Plcholder.MixProject do
  use Mix.Project

  def project do
    [
      app: :plcholder,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Plcholder.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:multibase, "~> 0.0.1"},
      {:ex_multihash, "~> 2.0.0"},
      {:rustler, "~> 0.32"},
      {:matcha, "~> 0.1"},
      {:varint, "~> 1.4"},
      {:jason, "~> 1.4"},
      {:httpoison, "~> 2.2"},
      {:ecto, "~> 3.11"},
      {:ecto_sqlite3, "~> 0.15"},
      {:postgrex, ">= 0.0.0"},
    ]
  end
end
