defmodule Dexts.Mixfile do
  use Mix.Project

  def project do
    [ app: :dexts,
      version: "0.3.1",
      deps:    deps,
      package: package,
      description: "dets wrapper for Elixir" ]
  end

  defp package do
    [ maintainers: ["meh", "cereal"],
      licenses: ["WTFPL"],
      links: %{"GitHub" => "https://github.com/meh/dexts"} ]
  end

  defp deps do
    [ { :datastructures, "~> 0.2" },
      { :ex_doc, "~> 0.11", only: [:dev] } ]
  end
end
