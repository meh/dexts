Code.require_file "test_helper.exs", __DIR__

defmodule DictTest do
  use ExUnit.Case

  setup do
    { :ok, t: Dexts.Dict.new!("test.dat") }
  end

  teardown meta do
    t = meta[:t]

    t |> Dexts.Dict.close
    File.rm("test.dat")

    :ok
  end

  test "read works", meta do
    t = meta[:t]

    assert t |> Dict.fetch(:a) == :error
  end

  test "write works", meta do
    t = meta[:t]

    t |> Dict.put :a, 2
    assert t |> Dict.fetch!(:a) == 2
  end

  test "size works", meta do
    t = meta[:t]

    assert t |> Dict.size == 0

    t |> Dict.put :a, 2
    t |> Dict.put :b, 4

    assert t |> Dict.size == 2
  end

  test "count works with pattern", meta do
    t = meta[:t]

    t |> Dict.put :a, 2
    t |> Dict.put :b, 4
    t |> Dict.put :c, 3

    assert t |> Dexts.Dict.count([{{ :_, :'$1' }, [{ :==, { :rem, :'$1', 2 }, 0 }], [{ :const, true }]}]) == 2
  end

  test "iteration works", meta do
    t = meta[:t]

    t |> Dict.put :a, 2
    t |> Dict.put :b, 4
    t |> Dict.put :c, 3

    assert Enum.map(t, fn(x) -> x end) == [{ :a, 2 }, { :b, 4 }, { :c, 3 }]
  end
end
