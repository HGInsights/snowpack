defmodule Snowpack.ODBCTest do
  use ExUnit.Case, async: false

  use Mimic

  import Snowpack.TestHelper

  test "handle_call/2 query when not_connected" do
    Mimic.set_mimic_global()

    expect(:odbc, :connect, fn _, _ -> {:error, "try again!"} end)

    {:ok, pid} = start_supervised({Snowpack, key_pair_opts()})

    assert {:error, :not_connected} = Snowpack.query(pid, "select 1")
  end

  test "handle_call/2 query when with_query_id: false and error" do
    Mimic.set_mimic_global()

    expect(:odbc, :param_query, fn _, _, _, _ -> {:error, "bad things!"} end)

    {:ok, pid} = start_supervised({Snowpack, key_pair_opts()})

    assert {:error, %Snowpack.Error{message: "bad things!"}} = Snowpack.query(pid, "select 1")
  end
end