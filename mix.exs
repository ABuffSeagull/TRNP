defmodule Trnp.MixProject do
  use Mix.Project

  def project do
    [
      app: :trnp,
      version: "3.1.1",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Trnp, []},
      extra_applications: [:logger, :timex]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:timex, "~> 3.6"},
      {:nostrum, "~> 0.4.1"},
      {:quantum, "~> 3.0.0-rc.3"},
      {:jason, "~> 1.2"},
      {:sqlitex, path: "../sqlitex"},
      {:credo, "~> 1.3", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false}
    ]
  end
end
