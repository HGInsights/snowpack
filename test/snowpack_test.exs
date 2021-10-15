defmodule SnowpackTest do
  use ExUnit.Case, async: false

  import Snowpack.TestHelper

  alias Snowpack.Result

  describe "connect" do
    @tag ciskip: true
    test "using ODBC.ini" do
      {:ok, pid} = Snowpack.start_link(odbc_ini_opts())

      assert {:ok, %Result{columns: ["1"], num_rows: 1, rows: [[1]]}} =
               Snowpack.query(pid, "SELECT 1")
    end

    test "using SNOWFLAKE_JWT key pair" do
      {:ok, pid} = Snowpack.start_link(key_pair_opts())

      assert {:ok, %Result{columns: ["1"], num_rows: 1, rows: [[1]]}} =
               Snowpack.query(pid, "SELECT 1")
    end

    @tag ciskip: true
    test "using Okta Authenticator" do
      {:ok, pid} = Snowpack.start_link(okta_opts())

      assert {:ok, %Result{columns: ["1"], num_rows: 1, rows: [[1]]}} =
               Snowpack.query(pid, "SELECT 1")
    end
  end

  describe "simple query" do
    setup [:connect]

    test "default protocol", %{pid: pid} do
      self = self()
      {:ok, _} = Snowpack.query(pid, "SELECT 42", [], log: &send(self, &1))
      assert_received %DBConnection.LogEntry{} = entry
      assert %Snowpack.Query{} = entry.query
    end

    test "with params", context do
      assert [[6]] = query("SELECT ? * ?", [2, 3])
    end
  end

  describe "snowflake sample db query" do
    setup [:connect]

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
  end

  describe "prepare & execute" do
    setup [:connect]

    test "succeeds", %{pid: pid} do
      {:ok, %Snowpack.Query{name: "times", statement: "SELECT ? * ?"} = query} =
        Snowpack.prepare(pid, "times", "SELECT ? * ?")

      {:ok, _query, %Snowpack.Result{rows: [row]}} = Snowpack.execute(pid, query, [2, 3])

      assert row == [6]
    end
  end

  #    credo:disable-for-next-line Credo.Check.Design.TagTODO
  #  TODO: Need to figure out a way to create tables in the standard Snwoflake Set of DBs or create a test DB
  #  describe "create objects" do
  #    setup [:connect]
  #
  #    test "can create and drop table", %{pid: pid} do
  #      assert {:ok, %Result{columns: nil, num_rows: 1, rows: nil}} =
  #               Snowpack.query(pid, "CREATE OR REPLACE TABLE test_table (amount number)")
  #
  #      assert {:ok, %Result{columns: nil, num_rows: 1, rows: nil}} =
  #               Snowpack.query(pid, "DROP TABLE test_table")
  #    end
  #  end

  defp connect(_context) do
    {:ok, pid} = Snowpack.start_link(key_pair_opts())

    {:ok, [pid: pid]}
  end
end
