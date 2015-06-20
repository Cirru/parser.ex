defmodule CirruParser.Mixfile do
  use Mix.Project

  def project do
    [app: :cirru_parser,
     description: "Cirru Parser in Elixir",
     version: "0.0.1",
     elixir: "~> 1.0",
     package: package,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:exjsx, "~> 3.1.0", only: [:dev, :test]}
    ]
  end

  defp package do
    [
      files: ["lib", "README.md", "mix.exs"],
      contributors: ["jiyinyiyong"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/Cirru/parser.ex"}
    ]
  end
end
