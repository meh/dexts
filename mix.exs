defmodule Dexts.Mixfile do
  use Mix.Project

  def project do
    [ app: :dexts,
      version: "0.2.0",
      elixir: "~> 0.14.3",
      package: package,
      description: "dets wrapper for Elixir" ]
  end

  defp package do
    [ contributors: ["meh"],
      licenses: ["WTFPL"],
      links: [ { "GitHub", "https://github.com/meh/dexts" } ] ]
  end
end
