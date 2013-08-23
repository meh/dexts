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

    args = case options[:mode] do
      :both -> [{ :access, :read_write } | args]
      :read -> [{ :access, :read } | args]

      nil -> args
    end

    args = case options[:type] do
      :set           -> [{ :type, :set } | args]
      :bag           -> [{ :type, :bag } | args]
      :duplicate_bag -> [{ :type, :duplicate_bag } | args]

      nil -> args
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
  Get the previous key in the given table, see `dets:prev`.
  """
  @spec prev(table, any) :: any | nil
  def prev(table, key) do
    case :dets.prev(table, key) do
      :"$end_of_table" -> nil
      key              -> key
    end
  end

  @doc """
  Get the last key in the given table, see `dets:prev`.
  """
  @spec last(table) :: any | nil
  def last(table) do
    case :dets.last(table) do
      :"$end_of_table" -> nil
      key              -> key
    end
  end

  @doc """
  Fold the given table from the left, see `dets:foldl`.
  """
  @spec foldl(table, any, (record, any -> any)) :: any
  def foldl(table, acc, fun) do
    :dets.foldl(fun, acc, table)
  end

  @doc """
  Fold the given table from the right, see `dets:foldr`.
  """
  @spec foldr(table, any, (record, any -> any)) :: any
  def foldr(table, acc, fun) do
    :dets.foldr(fun, acc, table)
  end

  def write(table, object, options // []) do
    if options[:overwrite] == false do
      :dets.insert_new(table, object)
    else
      :dets.insert(table, object)
    end
  end

  def save(table) do
    :dets.sync(table)
  end
end
