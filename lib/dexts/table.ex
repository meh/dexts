#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Dexts.Table do
  @opaque t :: { Dexts.Table, Dexts.table, :bag | :duplicate_bag | :set }

  defrecordp :table, __MODULE__, name: nil, type: nil, reference: nil

  def new(name, options // []) do
    if options[:automatic] != false do
      name      = Dexts.new!(name, options)
      reference = if options[:automatic] != false do
        Finalizer.define({ :destroy, name }, Process.whereis(Dexts.Manager))
      end

      table(name: name, type: options[:type] || :set, reference: reference)
    else
      table(name: Dexts.new!(name, options), type: options[:type] || :set)
    end
  end

  def name(table(name: name)) do
    name
  end

  def clear(table(name: name)) do
    Dexts.clear(name)
  end

  def close(table(name: name)) do
    Dexts.close(name)
  end

  def read(key, table(name: name)) do
    Dexts.read(name, key)
  end

  def at(slot, table(name: name)) do
    Dexts.at(name, slot)
  end

  def write(object, options // [], table(name: name)) do
    Dexts.write(name, object, options)
  end
end
