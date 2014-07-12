#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Dexts.Match do
  defstruct values: [], continuation: nil, whole: false

  alias Dexts.Match, as: Match
  alias Dexts.Selection, as: Selection

  def new(value, whole \\ false) do
    case value do
      :'$end_of_table' -> nil
      []               -> nil
      { [], _ }        -> nil

      { values, continuation } ->
        %Match{values: values, continuation: continuation, whole: whole}

      [_ | _] ->
        %Match{values: value, whole: whole}
    end
  end

  defimpl Selection do
    def next(%Match{continuation: nil}) do
      nil
    end

    def next(%Match{whole: true, continuation: continuation}) do
      Dexts.Match.new(:dets.match_object(continuation))
    end

    def values(%Match{values: values}) do
      values
    end
  end
end
