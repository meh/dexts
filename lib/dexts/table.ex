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

  def write(object, options // [], table(id: id)) do
    Dexts.write(id, object, options)
  end

  @spec save(t) :: none
  def save(table(id: id)) do
    Dexts.save(id)
  end
end
