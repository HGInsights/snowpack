defmodule SnowpackTest do
  use ExUnit.Case, async: true
  # import ExUnit.CaptureLog

  alias Snowpack.Result

  @odbc_ini_opts TestHelper.odbc_ini_opts()
  @key_pair_opts TestHelper.key_pair_opts()
  @okta_opts TestHelper.okta_opts()

  describe "connect" do
    @tag disabled: true
    test "connect using ODBC.ini" do
      {:ok, conn} = Snowpack.start_link(@odbc_ini_opts)

      assert {:ok, %Result{columns: ["1"], num_rows: 1, rows: [[1]]}} =
               Snowpack.query(conn, "SELECT 1")
    end

    test "connect using SNOWFLAKE_JWT key pair" do
      {:ok, conn} = Snowpack.start_link(@key_pair_opts)

      assert {:ok, %Result{columns: ["1"], num_rows: 1, rows: [[1]]}} =
               Snowpack.query(conn, "SELECT 1")
    end

    @tag disabled: true
    test "connect using Okta Authenticator" do
      {:ok, conn} = Snowpack.start_link(@okta_opts)

      assert {:ok, %Result{columns: ["1"], num_rows: 1, rows: [[1]]}} =
               Snowpack.query(conn, "SELECT 1")
    end
  end

  describe "query" do
    setup [:connect]

    test "default protocol", %{conn: conn} do
      self = self()
      {:ok, _} = Snowpack.query(conn, "SELECT 42", [], log: &send(self, &1))
      assert_received %DBConnection.LogEntry{} = entry
      assert %Snowpack.Query{} = entry.query
    end

    test "with params", %{conn: conn} do
      assert {:ok, result} = Snowpack.query(conn, "SELECT ? * ?", [2, 3])
      assert result.rows == [[6]]
    end

    test "snowflake sample db", %{conn: conn} do
      assert {:ok, result} =
               Snowpack.query(
                 conn,
                 "SELECT * FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER LIMIT 5;"
               )

      assert result.num_rows == 5
    end
  end

  describe "prepare & execute" do
    setup [:connect]

    test "succeeds", %{conn: conn} do
      {:ok, %Snowpack.Query{name: "", statement: "SELECT ? * ?"} = query} =
        Snowpack.prepare(conn, "", "SELECT ? * ?")

      {:ok, _query, %Snowpack.Result{rows: [row]}} = Snowpack.execute(conn, query, [2, 3])

      assert row == [6]
    end
  end

  defp connect(_context) do
    {:ok, conn} = Snowpack.start_link(@key_pair_opts)

    %{conn: conn}
  end
end
