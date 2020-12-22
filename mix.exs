defmodule Legolas.MixProject do
  use Mix.Project

  @version "0.1.1"

  def project do
    [
      app: :legolas,
      version: @version,
      elixir: "~> 1.2",
      start_permanent: Mix.env() == :prod,
      package: package(),
      deps: deps(),
      description: """
      Legolas - A process message interceptor for debug purposes
      """
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Legolas.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    []
  end

  defp package do
    [
      maintainers: ["Jorge Garrido"],
      licenses: ["MIT"],
      links: %{github: "https://github.com/zgbjgg/legolas"},
      files:
        ~w(lib LICENSE mix.exs README.md)
    ]
  end
end
