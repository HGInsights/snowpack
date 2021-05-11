defmodule QueryTest do
  use ExUnit.Case, async: true

  import Snowpack.TestHelper

  setup _context do
    {:ok, pid} = Snowpack.start_link(key_pair_opts())

    {:ok, [pid: pid]}
  end

  test "iodata", context do
    assert [[123]] = query(["S", ?E, ["LEC" | "T"], " ", '123'], [])
  end

  test "decode basic types", context do
    assert [[nil]] = query("SELECT NULL", [])
    assert [[true, false]] = query("SELECT true, false", [])
    assert [["e"]] = query("SELECT 'e'::char", [])
    assert [[42]] = query("SELECT 42", [])
    fourty_two = Decimal.new("42.0")
    assert [[^fourty_two]] = query("SELECT 42::float", [])
    date = ~D[2020-05-28]
    assert [[^date]] = query("SELECT '2020-05-28'::DATE", [])
    array = <<1, 2, 3>>
    assert [[array]] == query("SELECT array_construct(1, 2, 3)", [])

    #    credo:disable-for-next-line Credo.Check.Design.TagTODO
    #    TODO: Get working test for OBJECT type
    #    object = %{a: 1, b: 'BBBB'}
    #    assert [[^object]] =
    #             query("SELECT object_construct('a',1,'b','BBBB') as obj", [])
  end

  test "long number param", context do
    assert [["123456789012345678901"]] = query("SELECT ?", [123_456_789_012_345_678_901])
  end

  test "long string param", context do
    assert [["this_is_a_really_really_long_string"]] =
             query("SELECT ?", ["this_is_a_really_really_long_string"])
  end
end
