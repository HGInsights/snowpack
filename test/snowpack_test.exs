defmodule SnowpackTest do
  use ExUnit.Case, async: true

  import Snowpack.TestHelper

  alias Snowpack.Result

  describe "child_spec/1" do
    test "returns a child_spec woth given opts" do
      assert %{
               id: DBConnection.ConnectionPool,
               start:
                 {DBConnection.ConnectionPool, :start_link,
                  [{Snowpack.Protocol, [connection: [dsn: "snowpack"], pool_size: 1]}]}
             } = Snowpack.child_spec(odbc_ini_opts())
    end
  end

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

  describe "query/4" do
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

  describe "query!/4" do
    setup [:connect]

    test "returns result on success", %{pid: pid} do
      assert %Result{columns: ["1"], num_rows: 1, rows: [[1]]} = Snowpack.query!(pid, "SELECT 1")
    end

    test "raises on error", %{pid: pid} do
      assert_raise Snowpack.Error, fn ->
        Snowpack.query!(pid, "BAD QUERY")
      end
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

  describe "prepare! & execute!" do
    setup [:connect]

    test "succeeds", %{pid: pid} do
      query = Snowpack.prepare!(pid, "times", "SELECT ? * ?")

      %Snowpack.Result{rows: [row]} = Snowpack.execute!(pid, query, [2, 3])

      assert row == [6]
    end
  end

  describe "prepare_execute/4" do
    setup [:connect]

    test "returns result on success", %{pid: pid} do
      {:ok, %Snowpack.Query{name: "times"}, %Snowpack.Result{rows: [row]}} =
        Snowpack.prepare_execute(pid, "times", "SELECT ? * ?", [2, 3])

      assert row == [6]
    end

    test "returns exception on error", %{pid: pid} do
      {:error, %Snowpack.Error{odbc_code: "22018"}} =
        Snowpack.prepare_execute(pid, "times", "SELECT ? * ?", ["bad", "data"])
    end
  end

  describe "prepare_execute!/4" do
    setup [:connect]

    test "returns result on success", %{pid: pid} do
      {%Snowpack.Query{name: "times"}, %Snowpack.Result{rows: [row]}} =
        Snowpack.prepare_execute!(pid, "times", "SELECT ? * ?", [2, 3])

      assert row == [6]
    end

    test "raises exception on error", %{pid: pid} do
      assert_raise Snowpack.Error, fn ->
        Snowpack.prepare_execute!(pid, "times", "SELECT ? * ?", ["bad", "data"])
      end
    end
  end

  describe "prepare!/4" do
    setup [:connect]

    test "returns result on success", %{pid: pid} do
      %Snowpack.Query{name: "times", statement: "SELECT ? * ?"} =
        Snowpack.prepare!(pid, "times", "SELECT ? * ?")
    end
  end

  describe "close/3" do
    setup [:connect]

    test "succeeds", %{pid: pid} do
      {:ok, query} = Snowpack.prepare(pid, "times", "SELECT ? * ?")

      assert :ok = Snowpack.close(pid, query)
    end
  end

  describe "create objects" do
    setup [:connect]

    test "can create and drop table", %{pid: pid} do
      assert {:ok, %Result{columns: nil, num_rows: 1, rows: nil}} =
               Snowpack.query(
                 pid,
                 "CREATE OR REPLACE TABLE SNOWPACK.PUBLIC.TEST_TABLE (amount number)"
               )

      assert {:ok, %Result{columns: nil, num_rows: 1, rows: nil}} =
               Snowpack.query(pid, "DROP TABLE SNOWPACK.PUBLIC.TEST_TABLE")
    end
  end

  defp connect(_context) do
    {:ok, pid} = Snowpack.start_link(key_pair_opts())

    {:ok, [pid: pid]}
  end
end
