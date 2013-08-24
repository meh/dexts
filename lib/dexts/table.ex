#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Dexts.Table do
  @opaque t :: { Dexts.Table, Dexts.table, :bag | :duplicate_bag | :set }

  defrecordp :table, __MODULE__, id: nil, type: nil, reference: nil

  def new(name, options // []) do
    if options[:automatic] != false do
      id        = Dexts.new!(name, options)
      reference = if options[:automatic] != false do
        Finalizer.define({ :destroy, id }, Process.whereis(Dexts.Manager))
      end

      table(id: id, type: options[:type] || :set, reference: reference)
    else
      table(id: Dexts.new!(name, options), type: options[:type] || :set)
    end
  end

  def open(name, options // []) do
    if options[:automatic] != false do
      id        = Dexts.open!(name)
      reference = if options[:automatic] != false do
        Finalizer.define({ :destroy, id }, Process.whereis(Dexts.Manager))
      end

      table(id: id, type: options[:type] || :set, reference: reference)
    else
      table(id: Dexts.open!(name), type: options[:type] || :set)
    end
  end

  @doc """
  Get the id of the table, usable with the raw :dets functions or Exts wrapped
  ones.
  """
  def id(table(id: id)) do
    id
  end

  @doc """
  Clear the contents of the table, see `dets:delete_all_objects`.
  """
  def clear(table(id: id)) do
    Dexts.clear(id)
  end

  @doc """
  Close the table, see `dets:close`.
  """
  def close(table(id: id)) do
    Dexts.close(id)
  end

  @doc """
  Check if the table contains the given key.
  """
  @spec member?(term, t) :: boolean
  def member?(key, table(id: id)) do
    case Dexts.read(id, key) do
      [] -> false
      _  -> true
    end
  end

  @doc """
  Read terms from the table, if it's a set it returns a single term, otherwise
  it returns a list of terms, see `dets:lookup`.
  """
  @spec read(any, t) :: [term] | term
  def read(key, table(id: id, type: type)) when type in [:bag, :duplicate_bag] do
    case Dexts.read(id, key) do
      [] -> nil
      r  -> r
    end
  end

  def read(key, table(id: id, type: type)) when type in [:set] do
    Enum.first Dexts.read(id, key)
  end

  @doc """
  Read the terms in the given slot, see `dets:slot`.
  """
  def at(slot, table(id: id)) do
    Dexts.at(id, slot)
  end

  @doc """
  Get the first key in table, see `ets:first`.
  """
  @spec first(t) :: any
  def first(table(id: id)) do
    Dexts.first(id)
  end

  @doc """
  Get the next key in the table, see `ets:next`.
  """
  @spec next(any, t) :: any
  def next(key, table(id: id)) do
    Dexts.next(id, key)
  end

  @doc """
  Return an iterator for the table.
  """
  @spec to_sequence(t) :: Dexts.Table.Sequence.t
  def to_sequence(self) do
    Dexts.Table.Sequence.new(self)
  end

  @doc """
  Return an iterator for the table.
  """
  @spec to_sequence!(t) :: Dexts.Table.Sequence.t
  def to_sequence!(self) do
    Dexts.Table.Sequence.new(self, safe: false)
  end

  @doc """
  Select terms in the table using a match_spec, see `dets:select`.
  """
  @spec select(any, t) :: [any]
  def select(match_spec, table(id: id)) do
    Dexts.select(id, match_spec)
  end

  @doc """
  Select terms in the table using a match_spec and passing a limit,
  `dets:select`.
  """
  @spec select(integer, any, t) :: [any]
  def select(limit, match_spec, table(id: id)) do
    Dexts.select(limit, id, match_spec)
  end

  @doc """
  Match terms from the table with the given pattern, see `dets:match`.
  """
  @spec match(any, t) :: Match.t | nil
  def match(pattern, table(id: id)) do
    Dexts.match(id, pattern)
  end

  @doc """
  Match terms from the table with the given pattern and options or limit, see
  `dets:match`.
  """
  @spec match(any | integer, Keyword.t | any, t) :: Match.t | nil
  def match(limit_or_pattern, options_or_pattern, table(id: id)) do
    Dexts.match(id, limit_or_pattern, options_or_pattern)
  end

  @doc """
  Match terms from the table with the given pattern, options and limit, see
  `dets:match`.
  """
  @spec match(integer, any, Keyword.t, t) :: Match.t | nil
  def match(limit, pattern, options, table(id: id)) do
    Dexts.match(id, limit, pattern, options)
  end

  @doc """
  Get the number of terms in the table.
  """
  @spec count(t) :: non_neg_integer
  def count(table(id: id)) do
    Dexts.count(id)
  end

  @doc """
  Count the number of terms matching the match_spec, see `ets:select_count`.
  """
  @spec count(any, t) :: non_neg_integer
  def count(spec, table(id: id)) do
    Dexts.count(id, spec)
  end

  def write(object, options // [], table(id: id)) do
    Dexts.write(id, object, options)
  end

  @spec save(t) :: none
  def save(table(id: id)) do
    Dexts.save(id)
  end
end

defimpl Data.Dictionary, for: Dexts.Table do
  def get(self, key, default // nil) do
    case self.read(key) do
      { ^key, value } ->
        value

      nil ->
        default
    end
  end

  def get!(self, key) do
    case self.read(key) do
      { ^key, value } ->
        value

      nil ->
        raise Data.Missing, key: key
    end
  end

  def put(self, key, value) do
    self.write { key, value }
    self
  end

  def delete(self, key) do
    self.delete(key)
    self
  end

  def keys(self) do
    case self.select([{{ :'$1', :'$2' }, [], [:'$1'] }]) do
      nil -> []
      s   -> s.values
    end
  end

  def values(self) do
    case self.select([{{ :'$1', :'$2' }, [], [:'$2'] }]) do
      nil -> []
      s   -> s.values
    end
  end
end

defimpl Data.Contains, for: Dexts.Table do
  def contains?(self, { key, value }) do
    case self.read(key) do
      { ^key, ^value } ->
        true

      _ ->
        false
    end
  end

  def contains?(self, key) do
    case self.read(key) do
      { ^key, _ } ->
        true

      nil ->
        false
    end
  end
end

defimpl Data.Counted, for: Dexts.Table do
  def count(self) do
    self.size
  end
end

defimpl Data.Emptyable, for: Dexts.Table do
  def empty?(self) do
    self.count == 0
  end

  def clear(self) do
    self.clear
    self
  end
end

defimpl Data.Reducible, for: Dexts.Table do
  def reduce(self, acc, fun) do
    self.foldl(acc, fun)
  end
end

defimpl Data.Sequenceable, for: Dexts.Table do
  defdelegate to_sequence(self), to: Dexts.Table
end

defimpl Data.Listable, for: Dexts.Table do
  defdelegate to_list(self), to: Dexts.Table
end

defimpl Access, for: Dexts.Table do
  def access(table, key) do
    table.read(key)
  end
end

defimpl Inspect, for: Dexts.Table do
  import Inspect.Algebra

  def inspect(self, _opts) do
    concat ["#Dexts.Table<", Kernel.inspect(self.id, _opts), ">"]
  end
end
