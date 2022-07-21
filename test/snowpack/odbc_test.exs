defmodule Snowpack.ODBCTest do
  use ExUnit.Case, async: false

  use Mimic

  import Snowpack.TestHelper

  @tag :capture_log
  test "handle_call/2 query when not_connected" do
    Mimic.set_mimic_global()

    expect(:odbc, :connect, fn _, _ -> {:error, "try again!"} end)

    {:ok, pid} = start_supervised({Snowpack, key_pair_opts()})

    assert {:error, :not_connected} = Snowpack.query(pid, "select 1")
  end

  @tag :capture_log
  test "handle_call/2 query when with_query_id: false and error" do
    Mimic.set_mimic_global()

    expect(:odbc, :param_query, fn _, _, _, _ -> {:error, "bad things!"} end)

    {:ok, pid} = start_supervised({Snowpack, key_pair_opts()})

    assert {:error, %Snowpack.Error{message: "bad things!"}} = Snowpack.query(pid, "select 1", [], parse_results: false)
  end

  @tag :capture_log
  test "handle_call/2 query when last_query_id returns error" do
    Mimic.set_mimic_global()

    expect(:odbc, :sql_query, fn _, 'begin transaction;' -> :ok end)
    expect(:odbc, :sql_query, fn _, 'SELECT LAST_QUERY_ID() as query_id;' -> {:error, :very_bad_things} end)

    {:ok, pid} = start_supervised({Snowpack, key_pair_opts()})

    assert {:error, %Snowpack.Error{message: "very_bad_things"}} = Snowpack.query(pid, "select 1")
  end
end
