#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Dexts.Table.Sequence do
  @opaque t :: record

  defrecordp :sequence, __MODULE__, table: nil, key: nil, safe: true

  def new(table, rest // []) do
    if :dets.first(table.id) == :'$end_of_table' do
      nil
    else
      safe = Keyword.get(rest, :safe, true)

      sequence(table: table, safe: safe)
    end
  end

  def table(sequence(table: table)) do
    table
  end

  def safe?(sequence(safe: safe)) do
    safe
  end

  def first(sequence(table: table, key: key)) do
    if key == nil do
      key = table.first
    end

    table.read(key)
  end

  def next(sequence(table: table, key: key) = it) do
    if key == nil do
      key = table.first
    end

    case table.next(key) do
      nil ->
        nil

      key ->
        sequence(it, key: key)
    end
  end
end

defimpl Data.Reversible, for: Dexts.Table.Sequence do
  defdelegate reverse(self), to: Dexts.Table.Sequence
end

defimpl Data.Sequence, for: Dexts.Table.Sequence do
  defdelegate first(self), to: Dexts.Table.Sequence
  defdelegate next(self), to: Dexts.Table.Sequence
end

defimpl Enumerable, for: Dexts.Table.Sequence do
  def reduce(self, acc, fun) do
    Data.Seq.reduce(self, acc, fun)
  end

  def member?(enum, what) do
    enum.table.member?(what)
  end

  def count(self) do
    self.table.size
  end
end
