defmodule Dexts.Sequence do
  defstruct [:id, :key]
  alias __MODULE__, as: T

  def new(id) do
    %T{id: id, key: Dexts.first(id)}
  end

  alias Data.Protocol, as: P

  defimpl P.Sequence do
    def first(%T{id: id, key: key}) do
      case Dexts.read(id, key) do
        [] ->
          nil

        [{ _, value }] ->
          { key, value }

        values ->
          { key, for({ _, value } <- values, do: value) }
      end
    end

    def next(%T{id: id, key: key}) do
      case Dexts.next(id, key) do
        nil ->
          nil

        key ->
          %T{id: id, key: key}
      end
    end
  end
end
