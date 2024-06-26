defmodule ThatsNats.MixProject do
  use Mix.Project

  def project do
    [
      app: :thats_nats_ex,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ThatsNats.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:gnat, "~> 1.8"},
      {:jetstream, "~> 0.0.9"},
      {:jason, "~> 1.0"}
    ]
  end
end
