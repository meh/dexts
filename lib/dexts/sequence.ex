#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

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
