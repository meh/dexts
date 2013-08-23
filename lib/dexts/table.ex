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

  def id(table(id: id)) do
    id
  end

  def clear(table(id: id)) do
    Dexts.clear(id)
  end

  def close(table(id: id)) do
    Dexts.close(id)
  end

  def read(key, table(id: id)) do
    Dexts.read(id, key)
  end

  def at(slot, table(id: id)) do
    Dexts.at(id, slot)
  end

  def write(object, options // [], table(id: id)) do
    Dexts.write(id, object, options)
  end
end
