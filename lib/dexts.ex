#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Dexts do
  @type table :: term

  alias Dexts.FileError
  alias Dexts.Selection
  alias Dexts.Select
  alias Dexts.Match

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

  def open(path) when path |> is_binary do
    :dets.open_file(String.to_char_list(path))
  end

  def open!(path) do
    case open(path) do
      { :ok, name } ->
        name

      { :error, reason } ->
        raise FileError, reason: reason
    end
  end

  def new(name, options \\ []) when name |> is_binary do
    options = options
      |> Keyword.put_new(:index, 0)
      |> Keyword.put_new(:mode, :both)
      |> Keyword.put_new(:type, :set)

    :dets.open_file(String.to_char_list(name), Enum.flat_map(options, fn
      { :index, value } ->
        [{ :keypos, value + 1 }]

      { :path, value } ->
        [{ :file, value }]

      { :repair, value } ->
        [{ :repair, value }]

      { :version, value } ->
        [{ :version, value }]

      { :asynchronous, true } ->
        [{ :ram_file, true }]

      { :slots, value } ->
        Enum.map(value, fn
          { :min, value } ->
            { :min_no_slots, value }

          { :max, value } ->
            { :max_no_slots, value }
        end)

      { :save_every, value } ->
        [{ :auto_save, value }]

      { :mode, :both } ->
        [{ :access, :read_write }]

      { :mode, :read } ->
        [{ :access, :read }]

      { :type, :set } ->
        [{ :type, :set }]

      { :type, :bag } ->
        [{ :type, :bag }]

      { :type, :duplicate_bag } ->
        [{ :type, :duplicate_bag }]
    end))
  end

  def new!(name, options \\ []) when name |> is_binary do
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

  @doc """
  Delete the term matching the given pattern or key in the given table, see
  `ets:select_delete` and `ets:delete`.
  """
  @spec delete(table, any) :: true | integer
  def delete(table, [{ _, _, _ } | _] = match_spec) do
    :dets.select_delete(table, match_spec)
  end

  def delete(table, key) do
    :dets.delete(table, key)
  end

  @doc """
  Delete the given term from the given table, see `ets:delete_object`.
  """
  @spec delete!(table, term) :: true
  def delete!(table, object) do
    :dets.delete_object(table, object)
  end

  @doc """
  Select terms in the given table using a match_spec, see `dets:select`.
  """
  @spec select(table, any) :: Selection.t | nil
  def select(table, match_spec, options \\ [])

  def select(table, match_spec, []) do
    Select.new(:dets.select(table, match_spec))
  end

  def select(table, match_spec, limit: limit) do
    Select.new(:dets.select(table, match_spec, limit))
  end

  @doc """
  Match terms from the given table with the given pattern, see `dets:match`.
  """
  @spec match(table, any) :: Selection.t | nil
  def match(table, pattern) do
    Match.new(:dets.match(table, pattern))
  end

  @doc """
  Match terms from the given table with the given pattern and options, see
  `dets:match`.

  ## Options

  * `:whole` when true it returns the whole term.
  * `:delete` when true it deletes the matching terms instead of returning
    them.
  * `:limit` the amount of elements to select at a time.
  """
  @spec match(table, any | integer, Keyword.t | any) :: Selection.t | nil
  def match(table, pattern, delete: true) do
    :dets.match_delete(table, pattern)
  end

  def match(table, pattern, whole: true) do
    Match.new(:dets.match_object(table, pattern))
  end

  def match(table, pattern, limit: limit) do
    Match.new(:dets.match(table, pattern, limit))
  end

  def match(table, pattern, limit: limit, whole: true) do
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
  def write(table, object, options \\ [])

  def write(table, object, overwrite: false) do
    :dets.insert_new(table, object)
  end

  def write(table, object, []) do
    :dets.insert(table, object)
  end

  @doc """
  Synchronize the table to disk, see `dets:sync`.
  """
  @spec save(table) :: :ok | { :error, term }
  def save(table) do
    :dets.sync(table)
  end
end
