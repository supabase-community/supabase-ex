defmodule Supabase.MixProject do
  use Mix.Project

  @version "0.7.1"
  @source_url "https://github.com/supabase-community/supabase-ex"

  def project do
    [
      app: :supabase_potion,
      version: @version,
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package(),
      description: description(),
      elixirc_paths: elixirc_paths(Mix.env()),
      dialyzer: [plt_local_path: "priv/plts", ignore_warnings: ".dialyzerignore"]
    ]
  end

  defp elixirc_paths(e) when e in [:dev, :test], do: ["lib", "priv", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      mod: {Supabase.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:mime, "~> 2.0"},
      {:multipart, "~> 0.4.0"},
      {:finch, "~> 0.18"},
      {:ecto, "~> 3.10"},
      {:jason, "~> 1.4", optional: true},
      {:mox, "~> 1.2", only: :test},
      {:ex_doc, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.3", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    %{
      licenses: ["MIT"],
      contributors: ["zoedsoupe"],
      links: %{
        "GitHub" => @source_url,
        "Docs" => "https://hexdocs.pm/supabase_potion"
      },
      files: ~w[lib mix.exs README.md LICENSE]
    }
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "CHANGELOG.md"]
    ]
  end

  defp description do
    """
    Complete Elixir client for Supabase.
    """
  end
end
