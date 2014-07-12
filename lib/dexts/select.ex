#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Dexts.Select do
  defstruct values: [], continuation: nil

  alias Dexts.Select, as: Select
  alias Dexts.Selection, as: Selection

  def new(value) do
    case value do
      :'$end_of_table' -> nil
      []               -> nil
      { [], _ }        -> nil

      { values, continuation } ->
        %Select{values: values, continuation: continuation}

      [_ | _] ->
        %Select{values: value}
    end
  end

  defimpl Selection do
    def next(%Select{continuation: nil}) do
      nil
    end

    def next(%Select{continuation: continuation}) do
      Select.new(:dets.select(continuation))
    end

    def values(%Select{values: values}) do
      values
    end
  end
end
