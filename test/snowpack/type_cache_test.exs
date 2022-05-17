defmodule Snowpack.TypeCacheTest do
  use ExUnit.Case, async: true

  import Snowpack.TestHelper

  describe "get_column_types/1" do
    setup [:connect]

    test "column type parsing is cached on first call", context do
      statement = "SELECT C_CUSTKEY FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER LIMIT 1;"
      key = Snowpack.TypeCache.key_from_statement(statement)

      # force clean
      Mentat.delete(:type_cache, key)
      assert Snowpack.TypeCache.get_column_types(statement) == nil

      query(statement, [])

      assert {:ok, _column_types} = Snowpack.TypeCache.get_column_types(statement)
    end
  end

  defp connect(_context) do
    {:ok, pid} = Snowpack.start_link(key_pair_opts())

    {:ok, [pid: pid]}
  end
end
