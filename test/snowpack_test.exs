defmodule SnowpackTest do
  use ExUnit.Case, async: true
  # import ExUnit.CaptureLog

  alias Snowpack.Result

  @opts TestHelper.opts()

  describe "connect" do
    test "connect using default protocol" do
      {:ok, conn} = Snowpack.start_link(connection: @opts)

      assert {:ok, %Result{columns: ["1"], num_rows: 1, rows: [[1]]}} =
               Snowpack.query(conn, "SELECT 1")
    end
  end

  # SELECT * FROM ICEBERG ORDER BY ID;
  # UPDATE ICEBERG SET NAME='Hi' WHERE ID=1;
  # DELETE FROM ICEBERG WHERE ID=2;

  describe "query" do
    setup [:connect]

    test "default protocol", c do
      self = self()
      {:ok, _} = Snowpack.query(c.conn, "SELECT 42", [], log: &send(self, &1))
      assert_received %DBConnection.LogEntry{} = entry
      assert %Snowpack.Query{} = entry.query
    end

    test "with params", c do
      assert {:ok, result} = Snowpack.query(c.conn, "SELECT ? * ?", [2, 3])
      assert result.rows == [[6]]
    end
  end

  defp connect(c) do
    {:ok, conn} =
      Snowpack.start_link(
        connection: @opts,
        pool_size: 1,
        queue_target: 1000,
        queue_interval: 50_000
      )

    Map.put(c, :conn, conn)
  end
end
