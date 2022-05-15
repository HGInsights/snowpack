defmodule Snowpack.ProtocolTest do
  use ExUnit.Case, async: true

  use Mimic

  import Snowpack.TestHelper

  describe "handle_execute/4" do
    setup [:connect]

    test "with connection errors", %{pid: pid} do
      expect(Snowpack.ODBC, :query, fn _pid, _statement, _params, _opts, _with_query_id ->
        {:error, Snowpack.Error.exception({"08123", "123", "bad"})}
      end)

      assert {:error, %Snowpack.Error{odbc_code: :connection_exception}} = Snowpack.query(pid, "select 1;")
    end

    test "updated with no query_id", %{pid: pid} do
      # Snowpack.ODBC.query is called with `with_query_id` set to false when the types are cached
      expect(Snowpack.TypeCache, :get_column_types, fn _ -> {:ok, nil} end)

      expect(Snowpack.ODBC, :query, fn _pid, _statement, _params, _opts, false ->
        {:updated, :undefined}
      end)

      assert {:ok, %Snowpack.Result{num_rows: 0}} = Snowpack.query(pid, "begin transaction;")
    end

    test "updated with rows", %{pid: pid} do
      expect(Snowpack.ODBC, :query, fn _pid, _statement, _params, _opts, true ->
        {:updated, 1, [{"01a4456a-0401-73d1-0023-350366fe95b2"}]}
      end)

      assert {:ok, %Snowpack.Result{num_rows: 1}} = Snowpack.query(pid, "insert into table (col) values (1)")
    end
  end

  defp connect(_context) do
    {:ok, pid} = start_supervised({Snowpack, key_pair_opts()})

    {:ok, [pid: pid]}
  end
end
