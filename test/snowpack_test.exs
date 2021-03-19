defmodule SnowpackTest do
  use ExUnit.Case, async: true

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

    test "with params", %{pid: pid} do
      assert {:ok, result} = Snowpack.query(pid, "SELECT ? * ?", [2, 3])
      assert result.rows == [[6]]
    end
  end

  describe "snowflake sample db query" do
    setup [:connect]

    test "with params and rows", %{pid: pid} do
      assert {:ok, result} =
               Snowpack.query(
                 pid,
                 "SELECT * FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER LIMIT ?;",
                 [5]
               )

      assert result.num_rows == 5
    end

    test "with join, custom column, and date", %{pid: pid} do
      assert {:ok, result} =
               Snowpack.query(
                 pid,
                 """
                 SELECT ord.O_ORDERKEY, ord.O_ORDERSTATUS, ord.O_ORDERDATE, item.L_PARTKEY, 9 as number
                  FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS ord
                  INNER JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.LINEITEM item ON ord.O_ORDERKEY = item.L_ORDERKEY
                  LIMIT ? OFFSET ?;
                 """,
                 [2, 0]
               )

      assert result.num_rows == 2

      first_row = List.first(result.rows)
      assert %Date{} = Enum.at(first_row, 2)
      assert Enum.at(first_row, 4) == 9
    end
  end

  describe "prepare & execute" do
    setup [:connect]

    test "succeeds", %{pid: pid} do
      {:ok, %Snowpack.Query{name: "", statement: "SELECT ? * ?"} = query} =
        Snowpack.prepare(pid, "", "SELECT ? * ?")

      {:ok, _query, %Snowpack.Result{rows: [row]}} = Snowpack.execute(pid, query, [2, 3])

      assert row == [6]
    end
  end

  defp connect(_context) do
    {:ok, pid} = Snowpack.start_link(key_pair_opts())

    %{pid: pid}
  end
end
