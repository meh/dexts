defmodule Dexts.Mixfile do
  use Mix.Project

  def project do
    [ app: :dexts,
      version: "0.1.1",
      elixir: "~> 0.13.2",
      package: package,
      description: "dets wrapper for Elixir" ]
  end

  defp package do
    [ contributors: ["meh"],
      license: "WTFPL",
      links: [ { "GitHub", "https://github.com/meh/dexts" } ] ]
  end
end
