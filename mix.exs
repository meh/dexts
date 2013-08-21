defmodule Dexts.Mixfile do
  use Mix.Project

  def project do
    [ app: :dexts,
      version: "0.0.1",
      deps: deps ]
  end

  # Configuration for the OTP application
  def application do
    [ applications: [:finalizer],
      mod: { Dexts.Manager, [] } ]
  end

  # Returns the list of dependencies in the format:
  # { :foobar, "0.1", git: "https://github.com/elixir-lang/foobar.git" }
  defp deps do
    [ { :finalizer, github: "meh/elixir-finalizer" } ]
  end
end
