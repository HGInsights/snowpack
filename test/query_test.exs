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
