defmodule TypeParsingTest do
  use ExUnit.Case, async: false

  import Snowpack.TestHelper

  @table "SNOWPACK.PUBLIC.TYPES_TABLE"
  @query "SELECT * from #{@table} LIMIT 1;"

  @moduletag ciskip: true

  describe "type parsing" do
    setup [:connect]

    test "works for basic column types", %{pid: pid} do
      {:ok, _result} =
        Snowpack.query(
          pid,
          """
          CREATE OR REPLACE TABLE #{@table} (
            NUMBER NUMBER, FLOAT FLOAT,
            VARCHAR VARCHAR, CHAR CHAR, TEXT TEXT, BINARY BINARY,
            BOOLEAN BOOLEAN,
            DATE DATE, DATETIME DATETIME, TIME TIME,
            TIMESTAMP TIMESTAMP, TIMESTAMP_LTZ TIMESTAMP_LTZ,
            TIMESTAMP_NTZ TIMESTAMP_NTZ, TIMESTAMP_TZ TIMESTAMP_TZ
          )
          """
        )

      {:ok, _result} =
        Snowpack.query(
          pid,
          """
          INSERT INTO #{@table}
          (
            NUMBER, FLOAT, VARCHAR, CHAR, TEXT, BINARY, BOOLEAN, DATE, DATETIME, TIME,
            TIMESTAMP, TIMESTAMP_LTZ, TIMESTAMP_NTZ, TIMESTAMP_TZ
          )
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          """,
          [
            123,
            1.23,
            "これはテスト文字列です",
            "c",
            "text",
            Base.encode16("binary"),
            true,
            ~D[2015-01-13],
            ~U[2015-01-13T13:00:07.123+00:00],
            ~T[13:00:07],
            ~N[2015-01-13T13:00:07.123],
            ~N[2015-01-13T13:00:07.123],
            ~N[2015-01-13T13:00:07.123],
            ~U[2015-01-13T20:00:07.123Z]
          ]
        )

      assert {:ok,
              %Snowpack.Result{
                columns: [
                  "NUMBER",
                  "FLOAT",
                  "VARCHAR",
                  "CHAR",
                  "TEXT",
                  "BINARY",
                  "BOOLEAN",
                  "DATE",
                  "DATETIME",
                  "TIME",
                  "TIMESTAMP",
                  "TIMESTAMP_LTZ",
                  "TIMESTAMP_NTZ",
                  "TIMESTAMP_TZ"
                ],
                num_rows: 1,
                rows: [
                  [
                    123,
                    1.23,
                    "これはテスト文字列です",
                    "c",
                    "text",
                    "62696E617279",
                    true,
                    ~D[2015-01-13],
                    ~N[2015-01-13 13:00:07],
                    ~T[13:00:07],
                    ~N[2015-01-13 13:00:07],
                    ~N[2015-01-13 13:00:07],
                    ~N[2015-01-13 13:00:07],
                    ~N[2015-01-13 12:00:07]
                  ]
                ]
              }} = Snowpack.query(pid, @query)
    end

    # TODO: research support for custom Snowflake types.
    # ARRAY, OBJECT, VARIANT
    # https://docs.snowflake.com/en/user-guide/odbc-api.html#custom-sql-data-types

    # test "works for Snowflake ARRAY column type", %{pid: pid} do
    #   {:ok, _result} =
    #     Snowpack.query(
    #       pid,
    #       "CREATE OR REPLACE TABLE #{@table} (COL_ARRAY ARRAY)"
    #     )

    #   # # TODO: figure out how to encode arrays as params for ODBC
    #   # {:ok, _result} =
    #   #   Snowpack.query(pid, "INSERT INTO #{@table} (ARRAY) VALUES (?)", [
    #   #     [123, "one", "two", true]
    #   #   ])

    #   assert {:ok, _result} = Snowpack.query(pid, @query) |> IO.inspect(label: :query)
    # end
  end

  defp connect(_context) do
    {:ok, pid} = Snowpack.start_link(key_pair_opts())

    # force clean
    key = Snowpack.TypeCache.key_from_statement(@query)
    Mentat.delete(:type_cache, key)

    {:ok, [pid: pid]}
  end
end
