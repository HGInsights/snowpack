defmodule QueryTest do
  use ExUnit.Case, async: true

  import Snowpack.TestHelper

  describe "query" do
    setup [:connect]

    test "iodata", context do
      assert [[123]] = query(["S", ?E, ["LEC" | "T"], " ", '123'], [])
    end

    test "decode basic types", context do
      assert [[nil]] = query("SELECT NULL", [])

      assert [[true, false]] = query("SELECT true, false", [])

      assert [["e"]] = query("SELECT 'e'::char", [])

      assert [[42]] = query("SELECT 42", [])

      assert [[42.0]] == query("SELECT 42::float", [])

      date = ~D[2020-05-28]
      assert [[^date]] = query("SELECT '2020-05-28'::DATE", [])

      date_time = ~N[2020-05-28 01:23:34]
      assert [[^date_time]] = query("SELECT '2020-05-28 01:23:34'::DATETIME", [])

      array = [1, 2, 3]
      assert [[^array]] = query("SELECT array_construct(1, 2, 3)", [])
    end

    test "long number param", context do
      assert [[123_456_789_012_345_678_901]] = query("SELECT ?", [123_456_789_012_345_678_901])
    end

    test "long string param", context do
      assert [["this_is_a_really_really_long_string"]] = query("SELECT ?", ["this_is_a_really_really_long_string"])
    end

    test "with params and rows", context do
      rows = query("SELECT * FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER LIMIT ?;", [5])

      assert length(rows) == 5
    end

    test "with join, custom column, where like, and date", context do
      assert [first_row, _second_row] =
               query(
                 """
                 SELECT ord.O_ORDERKEY, ord.O_ORDERSTATUS, ord.O_ORDERDATE, item.L_PARTKEY, 9 as number
                  FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS ord
                  INNER JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.LINEITEM item ON ord.O_ORDERKEY = item.L_ORDERKEY
                  WHERE ord.O_COMMENT LIKE ?
                  LIMIT ? OFFSET ?;
                 """,
                 ["%he carefully stealthy deposits.%", 2, 0]
               )

      assert %Date{} = Enum.at(first_row, 2)
      assert Enum.at(first_row, 4) == 9
    end

    test "column type parsing is cached on first call", context do
      statement = "SELECT C_CUSTKEY FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER LIMIT ?;"
      key = Snowpack.TypeCache.key_from_statement(statement)

      # force clean
      Mentat.delete(:type_cache, key)
      assert Snowpack.TypeCache.get_column_types(statement) == nil

      rows = query(statement, [7])
      assert length(rows) == 7

      assert {:ok, _column_types} = Snowpack.TypeCache.get_column_types(statement)
    end
  end

  defp connect(_context) do
    {:ok, pid} = Snowpack.start_link(key_pair_opts())

    {:ok, [pid: pid]}
  end
end
