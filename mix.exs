defmodule Dexts.Mixfile do
  use Mix.Project

  def project do
    [ app: :dexts,
      version: "0.2.0",
      elixir: "~> 1.0.0",
      package: package,
      description: "dets wrapper for Elixir" ]
  end

  defp package do
    [ contributors: ["meh", "cereal"],
      licenses: ["WTFPL"],
      links: [ { "GitHub", "https://github.com/meh/dexts" } ] ]
  end
end
