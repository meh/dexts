#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Dexts do
  defexception FileError, reason: nil do
    @moduledoc """
    Exception thrown if an error occurs when opening a table.
    """

    @spec message(t) :: String.t
    def message(FileError[reason: reason]) do
      reason
    end
  end

  @type table :: term

  @spec info(table) :: Keyword.t | nil
  def info(table) do
    case :dets.info(table) do
      :undefined -> nil
      value      -> value
    end
  end

  @spec info(table, atom) :: term | nil
  def info(table, key) do
    case :dets.info(table, key) do
      :undefined -> nil
      value      -> value
    end
  end

  def open(path) do
    if path |> is_binary do
      path = String.to_char_list! path
    end

    :dets.open_file(path)
  end

  def open!(path) do
    case open(path) do
      { :ok, name } ->
        name

      { :error, reason } ->
        raise FileError, reason: reason
    end
  end

  def new(name, options // []) do
    if name |> is_binary do
      name = String.to_char_list! name
    end

    args = []

    args = [{ :keypos, (options[:index] || 0) + 1 } | args]

    if options[:path] do
      args = [{ :file, options[:path] } | args]
    end

    if options[:repair] do
      args = [{ :repair, options[:repair] } | args]
    end

    if options[:version] do
      args = [{ :version, options[:version] } | args]
    end

    if options[:asynchronous] do
      args = [{ :ram_file, true } | args]
    end

    if slots = options[:slots] do
      if slots[:min] do
        args = [{ :min_no_slots, slots[:min] } | args]
      end

      if slots[:max] do
        args = [{ :max_no_slots, slots[:max] } | args]
      end
    end

    if options[:save_every] do
      args = [{ :auto_save, options[:save_every] } | args]
    end

    args = case options[:mode] || :both do
      :both -> [{ :access, :read_write } | args]
      :read -> [{ :access, :read } | args]
    end

    args = case options[:type] || :set do
      :set           -> [{ :type, :set } | args]
      :bag           -> [{ :type, :bag } | args]
      :duplicate_bag -> [{ :type, :duplicate_bag } | args]
    end

    :dets.open_file(name, args)
  end

  def new!(name, options // []) do
    case new(name, options) do
      { :ok, name } ->
        name

      { :error, reason } ->
        raise FileError, reason: reason
    end
  end

  def clear(table) do
    :dets.delete_all_objects(table)
  end

  def close(table) do
    :dets.close(table)
  end

  def read(table, key) do
    :dets.lookup(table, key)
  end

  def at(table, slot) do
    case :dets.slot(table, slot) do
      :'$end_of_table' -> nil
      r                -> r
    end
  end

  @doc """
  Get the first key in the given table, see `dets:first`.
  """
  @spec first(table) :: any | nil
  def first(table) do
    case :dets.first(table) do
      :"$end_of_table" -> nil
      key              -> key
    end
  end

  @doc """
  Get the next key in the given table, see `dets:next`.
  """
  @spec next(table, any) :: any | nil
  def next(table, key) do
    case :dets.next(table, key) do
      :"$end_of_table" -> nil
      key              -> key
    end
  end

  @doc """
  Get the keys in the given table.
  """
  @spec keys(table) :: [term]
  def keys(table) do
    do_keys([], table, first(table))
  end

  defp do_keys(acc, _, nil) do
    acc
  end

  defp do_keys(acc, table, key) do
    [key | acc] |> do_keys(table, next(table, key))
  end

  @doc """
  Fold the given table from the left, see `dets:foldl`.
  """
  @spec foldl(table, any, (term, any -> any)) :: any
  def foldl(table, acc, fun) do
    :dets.foldl(fun, acc, table)
  end

  @doc """
  Fold the given table from the right, see `dets:foldr`.
  """
  @spec foldr(table, any, (term, any -> any)) :: any
  def foldr(table, acc, fun) do
    :dets.foldr(fun, acc, table)
  end

  defmodule Selection do
    @moduledoc """
    Selection wraps an `dets:select` result, which may or may not contain a
    continuation, in case of continuations you can access the next set of
    values by calling `.next`.
    """

    @opaque t :: record

    defrecordp :selection, __MODULE__, values: [], continuation: nil

    @doc """
    Get a Selection from the various select results.
    """
    @spec new(:'$end_of_table' | list | { list, any }) :: t | nil
    def new(value) do
      case value do
        :'$end_of_table' -> nil
        []               -> nil
        { [], _ }        -> nil

        { v, c } -> selection(values: v, continuation: c)
        [_ | _]  -> selection(values: value)
      end
    end

    @doc """
    Get the values in the current Selection.
    """
    @spec values(t) :: [any]
    def values(selection(values: v)) do
      v
    end

    @doc """
    Get the next set of values wrapped in another Selection, returns nil if
    there are no more.
    """
    @spec next(t) :: t | nil
    def next(selection(continuation: nil)) do
      nil
    end

    def next(selection(continuation: c)) do
      new(:dets.select(c))
    end
  end

  @doc """
  Select terms in the given table using a match_spec, see `dets:select`.
  """
  @spec select(table, any) :: Selection.t | nil
  def select(table, match_spec) do
    Selection.new(:dets.select(table, match_spec))
  end

  @doc """
  Select terms in the given table using a match_spec passing a limit, see
  `dets:select`.
  """
  @spec select(table, non_neg_integer, any) :: Selection.t | nil
  def select(table, limit, match_spec) when is_integer limit do
    Selection.new(:dets.select(table, match_spec, limit))
  end

  defmodule Match do
    @moduledoc """
    Match wraps an `dets:match` or `dets:match_object` result, which may or may
    not contain a continuation, in case of continuations you can access the
    next set of values by calling `.next`.
    """

    @opaque t :: record

    defrecordp :match, __MODULE__, values: [], continuation: nil, whole: false

    @doc """
    Get a Match from the various match results.
    """
    def new(value, whole // false) do
      case value do
        :'$end_of_table' -> nil
        []               -> nil
        { [], _ }        -> nil

        { v, c } -> match(values: v, continuation: c, whole: whole)
        [_ | _]  -> match(values: value, whole: whole)
      end
    end

    @doc """
    Check if the Match is matching whole objects.
    """
    @spec whole?(t) :: boolean
    def whole?(match(whole: whole)) do
      whole
    end

    @doc """
    Get the values in the current Match.
    """
    @spec values(t) :: [any]
    def values(match(values: v)) do
      v
    end

    @doc """
    Get the next set of values wrapped in another Match, returns nil if there
    are no more.
    """
    @spec next(t) :: Match.t | nil
    def next(match(continuation: nil)) do
      nil
    end

    def next(match(whole: true, continuation: c)) do
      new(:dets.match_object(c))
    end

    def next(match(whole: false, continuation: c)) do
      new(:dets.match(c))
    end
  end

  @doc """
  Match terms from the given table with the given pattern, see `dets:match`.
  """
  @spec match(table, any) :: Match.t | nil
  def match(table, pattern) do
    Match.new(:dets.match(table, pattern))
  end

  @doc """
  Match terms from the given table with the given pattern and options or
  limit, see `dets:match`.

  ## Options

  * `:whole` when true it returns the whole term.
  * `:delete` when true it deletes the matching terms instead of returning
    them.
  """
  @spec match(table, any | integer, Keyword.t | any) :: Match.t | nil
  def match(table, pattern, delete: true) do
    :dets.match_delete(table, pattern)
  end

  def match(table, pattern, whole: true) do
    Match.new(:dets.match_object(table, pattern))
  end

  def match(table, limit, pattern) when is_integer limit do
    Match.new(:dets.match(table, pattern, limit))
  end

  @doc """
  Match term from the given table with the given pattern, options and limit,
  see `dets:match_object`.
  """
  @spec match(table, integer, any, Keyword.t) :: Match.t | nil
  def match(table, limit, pattern, whole: true) do
    Match.new(:dets.match_object(table, pattern, limit))
  end

  @doc """
  Get the number of terms in the given table.
  """
  @spec count(table) :: non_neg_integer
  def count(table) do
    info(table, :size)
  end

  @doc """
  Count the number of terms matching the match_spec.
  """
  @spec count(table, any) :: non_neg_integer
  def count(table, match_spec) do
    case select(table, match_spec) do
      nil ->
        0

      selection ->
        selection.values |> length
    end
  end

  @doc """
  Write the given term to the given table optionally disabling overwriting,
  see `dets:insert` and `dets:insert_new`.
  """
  @spec write(table, term)            :: boolean
  @spec write(table, term, Keyword.t) :: boolean
  def write(table, object, options // []) do
    if options[:overwrite] == false do
      :dets.insert_new(table, object)
    else
      :dets.insert(table, object)
    end
  end

  @doc """
  Synchronize the table to disk, see `dets:sync`.
  """
  @spec save(table) :: :ok | { :error, term }
  def save(table) do
    :dets.sync(table)
  end
end
