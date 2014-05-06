#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Dexts.Dict do
  defstruct [:id, :type]

  alias __MODULE__, as: T

  use Dict.Behaviour

  def new do
    raise FileError
  end

  @doc """
  Wrap a table or create one with the passed options.
  """
  @spec new(integer | atom | Keyword.t) :: t
  def new(name, options \\ []) do
    case Dexts.new(name, options) do
      { :ok, id } ->
        { :ok, %T{id: id, type: options[:type] || :set} }

      { :error, reason } ->
        { :error, reason }
    end
  end

  def new!(name, options \\ []) do
    %T{id: Dexts.new!(name, options), type: options[:type] || :set}
  end

  def open(name) do
    case Dexts.open(name) do
      { :error, reason } ->
        { :error, reason }

      { :ok, id } ->
        { :ok, %T{id: id, type: Dexts.info(id, :type)} }
    end
  end

  def open!(name) do
    id = Dexts.open!(name)

    %T{id: id, type: Dexts.info(id, :type)}
  end

  @doc """
  Check if the table is a bag.
  """
  @spec bag?(t) :: boolean
  def bag?(%T{type: type}) do
    type == :bag
  end

  @doc """
  Check if the table is a duplicate bag.
  """
  @spec duplicate_bag?(t) :: boolean
  def duplicate_bag?(%T{type: type}) do
    type == :duplicate_bag
  end

  @doc """
  Check if the table is a set.
  """
  @spec set?(t) :: boolean
  def set?(%T{type: type}) do
    type == :set
  end

  @doc """
  Get info about the table, see `dets:info`.
  """
  @spec info(t) :: [any] | nil
  def info(%T{id: id}) do
    Dexts.info(id)
  end

  @doc """
  Get info about the table, see `dets:info`.
  """
  @spec info(t, atom) :: any | nil
  def info(%T{id: id}, key) do
    Dexts.info(id, key)
  end

  def size(%T{id: id}) do
    Dexts.count(id)
  end

  @doc """
  Clear the contents of the table, see `dets:delete_all_objects`.
  """
  def clear(%T{id: id}) do
    Dexts.clear(id)
  end

  @doc """
  Close the table, see `dets:close`.
  """
  def close(%T{id: id}) do
    Dexts.close(id)
  end

  def delete(%T{id: id}, key_or_pattern) do
    Dexts.delete(id, key_or_pattern)
  end

  def put(%T{id: id} = self, key, value) do
    Dexts.write id, { key, value }

    self
  end

  def fetch(%T{id: id, type: type}, key) when type in [:bag, :duplicate_bag] do
    case Dexts.read(id, key) do
      [] ->
        :error

      values ->
        { :ok, for({ _, value } <- values, do: value) }
    end
  end

  def fetch(%T{id: id, type: type}, key) when type in [:set, :ordered_set] do
    case Dexts.read(id, key) do
      [] ->
        :error

      [{ _, value }] ->
        { :ok, value }
    end
  end

  def update(self, key, initial, fun) do
    case fetch(self, key) do
      { :ok, value } ->
        put(self, key, fun.(value))

      :error ->
        put(self, key, initial)
    end
  end

  def update!(self, key, fun) do
    case fetch(self, key) do
      { :ok, value } ->
        put(self, key, fun.(value))

      :error ->
        raise KeyError, key: key, term: self
    end
  end

  @doc """
  Read the terms in the given slot, see `ets:slot`.
  """
  @spec at(integer, t) :: [term]
  def at(%T{id: id}, slot) do
    Dexts.at(id, slot)
  end

  @doc """
  Get the first key in table, see `ets:first`.
  """
  @spec first(t) :: any
  def first(%T{id: id}) do
    Dexts.first(id)
  end

  @doc """
  Get the next key in the table, see `ets:next`.
  """
  @spec next(any, t) :: any
  def next(%T{id: id}, key) do
    Dexts.next(id, key)
  end

  @doc """
  Get the previous key in the table, see `ets:prev`.
  """
  @spec prev(any, t) :: any
  def prev(%T{id: id}, key) do
    Dexts.prev(id, key)
  end

  @doc """
  Get the last key in the table, see `ets:last`.
  """
  @spec last(t) :: any
  def last(%T{id: id}) do
    Dexts.last(id)
  end

  def keys(self) do
    case select(self, [{{ :'$1', :'$2' }, [], [:'$1'] }]) do
      nil -> []
      s   -> s.values
    end
  end

  def values(self) do
    case select(self, [{{ :'$1', :'$2' }, [], [:'$2'] }]) do
      nil -> []
      s   -> s.values
    end
  end

  @doc """
  Select terms in the table using a match_spec, see `ets:select`.
  """
  @spec select(t, any, Keyword.t) :: [any]
  def select(%T{id: id}, match_spec, options \\ []) do
    Dexts.select(id, match_spec, options)
  end

  @doc """
  Select terms in the table using a match_spec, traversing in reverse, see
  `ets:select_reverse`.
  """
  @spec reverse_select(t, any) :: [any]
  def reverse_select(%T{id: id}, match_spec, options \\ []) do
    Dexts.reverse_select(id, match_spec, options)
  end

  @doc """
  Match terms from the table with the given pattern, see `ets:match`.
  """
  @spec match(t, any) :: Match.t | nil
  def match(%T{id: id}, pattern, options \\ []) do
    Dexts.match(id, pattern, options)
  end

  @doc """
  Get the number of terms in the table.
  """
  @spec count(t) :: non_neg_integer
  def count(%T{id: id}) do
    Dexts.count(id)
  end

  @doc """
  Count the number of terms matching the match_spec, see `ets:select_count`.
  """
  @spec count(t, any) :: non_neg_integer
  def count(%T{id: id}, spec) do
    Dexts.count(id, spec)
  end

  @doc """
  Fold the table from the left, see `ets:foldl`.
  """
  @spec foldl(t, any, (term, any -> any)) :: any
  def foldl(%T{id: id}, acc, fun) do
    Dexts.foldl(id, acc, fun)
  end

  @doc """
  Fold the table from the right, see `ets:foldr`.
  """
  @spec foldr(t, any, (term, any -> any)) :: any
  def foldr(%T{id: id}, acc, fun) do
    Dexts.foldr(id, acc, fun)
  end

  @doc false
  def reduce(table, acc, fun) do
    reduce(table, first(table), acc, fun)
  end

  defp reduce(_table, _key, { :halt, acc }, _fun) do
    { :halted, acc }
  end

  defp reduce(table, key, { :suspend, acc }, fun) do
    { :suspended, acc, &reduce(table, key, &1, fun) }
  end

  defp reduce(_table, nil, { :cont, acc }, _fun) do
    { :done, acc }
  end

  defp reduce(table, key, { :cont, acc }, fun) do
    reduce(table, next(table, key), fun.({ key, fetch!(table, key) }, acc), fun)
  end

  defimpl Access do
    def access(table, key) do
      Dict.get(table, key)
    end
  end

  defimpl Enumerable do
    def reduce(table, acc, fun) do
      Dexts.Dict.reduce(table, acc, fun)
    end

    def member?(table, { key, value }) do
      { :ok, match?({ :ok, ^value }, Dexts.Dict.fetch(table, key)) }
    end

    def member?(_, _) do
      { :ok, false }
    end

    def count(table) do
      { :ok, Dexts.Dict.count(table) }
    end
  end
end
