#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Dexts.Dict do
  defstruct [:id, :type]
  @opaque t :: %Dexts.Dict{}
  alias __MODULE__, as: T

  def new do
    raise Dexts.FileError
  end

  @doc """
  Wrap a table or create one with the passed options.
  """
  @spec new(integer | atom | Keyword.t) :: t
  def new(name, options \\ []) do
    case Dexts.new(name, options) do
      { :ok, id } ->
        { :ok, %__MODULE__{id: id, type: options[:type] || :set} }

      { :error, reason } ->
        { :error, reason }
    end
  end

  @doc """
  Wrap a table or create one with the passed options.
  """
  def new!(name, options \\ []) do
    %__MODULE__{id: Dexts.new!(name, options), type: options[:type] || :set}
  end

  @doc """
  Open an already existing table.
  """
  def open(name) do
    case Dexts.open(name) do
      { :error, reason } ->
        { :error, reason }

      { :ok, id } ->
        { :ok, %__MODULE__{id: id, type: Dexts.info(id, :type)} }
    end
  end

  @doc """
  Open an already existing table.
  """
  def open!(name) do
    id = Dexts.open!(name)

    %__MODULE__{id: id, type: Dexts.info(id, :type)}
  end

  @doc """
  Check if the table is a bag.
  """
  @spec bag?(t) :: boolean
  def bag?(%__MODULE__{type: type}) do
    type == :bag
  end

  @doc """
  Check if the table is a duplicate bag.
  """
  @spec duplicate_bag?(t) :: boolean
  def duplicate_bag?(%__MODULE__{type: type}) do
    type == :duplicate_bag
  end

  @doc """
  Check if the table is a set.
  """
  @spec set?(t) :: boolean
  def set?(%__MODULE__{type: type}) do
    type == :set
  end

  @doc """
  Get info about the table, see `dets:info`.
  """
  @spec info(t) :: [any] | nil
  def info(%__MODULE__{id: id}) do
    Dexts.info(id)
  end

  @doc """
  Get info about the table, see `dets:info`.
  """
  @spec info(t, atom) :: any | nil
  def info(%__MODULE__{id: id}, key) do
    Dexts.info(id, key)
  end

  @doc """
  Clear the contents of the table, see `dets:delete_all_objects`.
  """
  def clear(%__MODULE__{id: id}) do
    Dexts.clear(id)
  end

  @doc """
  Close the table, see `dets:close`.
  """
  def close(%__MODULE__{id: id}) do
    Dexts.close(id)
  end

  def delete(%__MODULE__{id: id}, key_or_pattern) do
    Dexts.delete(id, key_or_pattern)
  end

  def put(%__MODULE__{id: id} = self, key, value) do
    Dexts.write id, { key, value }

    self
  end

  def fetch(%__MODULE__{id: id, type: type}, key) when type in [:bag, :duplicate_bag] do
    case Dexts.read(id, key) do
      [] ->
        :error

      values ->
        { :ok, for({ _, value } <- values, do: value) }
    end
  end

  def fetch(%__MODULE__{id: id, type: type}, key) when type in [:set, :ordered_set] do
    case Dexts.read(id, key) do
      [] ->
        :error

      [{ _, value }] ->
        { :ok, value }
    end
  end

  @doc """
  Read the terms in the given slot, see `ets:slot`.
  """
  @spec at(integer, t) :: [term]
  def at(%__MODULE__{id: id}, slot) do
    Dexts.at(id, slot)
  end

  @doc """
  Get the first key in table, see `ets:first`.
  """
  @spec first(t) :: any
  def first(%__MODULE__{id: id}) do
    Dexts.first(id)
  end

  @doc """
  Get the next key in the table, see `ets:next`.
  """
  @spec next(any, t) :: any
  def next(%__MODULE__{id: id}, key) do
    Dexts.next(id, key)
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
  @spec select(t, any, Keyword.t) :: Dexts.Selection.t | nil
  def select(%__MODULE__{id: id}, match_spec, options \\ []) do
    Dexts.select(id, match_spec, options)
  end

    @doc """
  Match terms from the table with the given pattern, see `ets:match`.
  """
  @spec match(t, any) :: Dexts.Selection.t | nil
  def match(%__MODULE__{id: id}, pattern, options \\ []) do
    Dexts.match(id, pattern, options)
  end

  @doc """
  Get the number of terms in the table.
  """
  @spec count(t) :: non_neg_integer
  def count(%__MODULE__{id: id}) do
    Dexts.count(id)
  end

  @doc """
  Count the number of terms matching the match_spec, see `ets:select_count`.
  """
  @spec count(t, any) :: non_neg_integer
  def count(%__MODULE__{id: id}, spec) do
    Dexts.count(id, spec)
  end

  @doc """
  Fold the table from the left, see `ets:foldl`.
  """
  @spec foldl(t, any, (term, any -> any)) :: any
  def foldl(%__MODULE__{id: id}, acc, fun) do
    Dexts.foldl(id, acc, fun)
  end

  @doc """
  Fold the table from the right, see `ets:foldr`.
  """
  @spec foldr(t, any, (term, any -> any)) :: any
  def foldr(%__MODULE__{id: id}, acc, fun) do
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
    reduce(table, next(table, key), fun.({ key, Data.Dict.get!(table, key) }, acc), fun)
  end

  alias Data.Protocol, as: P

  defimpl P.Dictionary do
    defdelegate fetch(self, key), to: T
    defdelegate put(self, key, value), to: T
    defdelegate delete(self, key), to: T
    defdelegate keys(self), to: T
    defdelegate values(self), to: T
  end

  defimpl P.Empty do
    def empty?(self) do
      Dexts.Dict.count(self) == 0
    end

    defdelegate clear(self), to: T
  end

  defimpl P.Count do
    defdelegate count(self), to: T
  end

  defimpl P.Reduce do
    defdelegate reduce(self, acc, fun), to: T
  end

  defimpl P.ToSequence do
    def to_sequence(%T{id: id}) do
      Dexts.Sequence.new(id)
    end
  end

  defimpl P.Contains do
    def contains?(self, key) do
      match? { :ok, _ }, T.fetch(self, key)
    end
  end

  defimpl Enumerable do
    use Data.Enumerable
  end
end
