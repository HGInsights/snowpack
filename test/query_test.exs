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
  end

  test "long number param", context do
    assert [["123456789012345678901"]] = query("SELECT ?", [123_456_789_012_345_678_901])
  end

  test "long string param", context do
    assert [["this_is_a_really_really_long_string"]] =
             query("SELECT ?", ["this_is_a_really_really_long_string"])
  end

  test "> 20 char params", context do
    stmt = """
      SELECT ord.O_ORDERKEY, ord.O_ORDERSTATUS, ord.O_ORDERDATE, item.L_PARTKEY, 9 as number
      FROM ORDERS ord
      INNER JOIN LINEITEM item ON ord.O_ORDERKEY = item.L_ORDERKEY
      WHERE ord.O_COMMENT ILIKE ?
      LIMIT ? OFFSET ?;
    """

    params = ["%stealthy%", 1, 0]

    query(stmt, params) |> IO.inspect(label: :query)

    for _x <- 1..50 do
      query(stmt, ["%1234567890123456789012%", 1, 0]) |> IO.inspect(label: :query)
    end
  end
end
