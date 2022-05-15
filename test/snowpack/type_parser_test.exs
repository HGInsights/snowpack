defmodule Snowpack.TypeParserTest do
  use ExUnit.Case, async: false

  import Snowpack.TestHelper

  alias Snowpack.TypeParser

  describe "parse_rows/3" do
    # rows: [
    #   {"123", 1.23, "これはテスト文字列です", "c", "text",
    #    "62696E617279", true, "2015-01-13", {{2015, 1, 13}, {13, 0, 7}}, "13:00:07",
    #    {{2015, 1, 13}, {13, 0, 7}}, {{2015, 1, 13}, {13, 0, 7}},
    #    {{2015, 1, 13}, {13, 0, 7}}, {{2015, 1, 13}, {12, 0, 7}}}
    # ]
    # parse: [
    #   [123, 1.23, "これはテスト文字列です", "c", "text", "62696E617279",
    #    true, ~D[2015-01-13], ~N[2015-01-13 13:00:07], ~T[13:00:07],
    #    ~N[2015-01-13 13:00:07], ~N[2015-01-13 13:00:07], ~N[2015-01-13 13:00:07],
    #    ~N[2015-01-13 12:00:07]]
    # ]

    test "parses VARCHAR column" do
      assert [["test"]] = TypeParser.parse_rows(%{"COL_NAME" => :default}, ['COL_NAME'], [{"test"}])
    end

    test "parses CHAR column" do
      assert [["x"]] = TypeParser.parse_rows(%{"COL_NAME" => :default}, ['COL_NAME'], [{"x"}])
    end

    test "parses TEXT column" do
      assert [["text"]] = TypeParser.parse_rows(%{"COL_NAME" => :default}, ['COL_NAME'], [{"text"}])
    end

    test "parses NUMBER column" do
      assert [[123]] = TypeParser.parse_rows(%{"COL_NAME" => :integer}, ['COL_NAME'], [{"123"}])
    end

    test "parses FLOAT column" do
      assert [[12.33]] = TypeParser.parse_rows(%{"COL_NAME" => :float}, ['COL_NAME'], [{12.33}])
    end

    test "parses DECIMAL column" do
      decimal = Decimal.new("12.33")
      assert [[^decimal]] = TypeParser.parse_rows(%{"COL_NAME" => :float}, ['COL_NAME'], [{"12.33"}])
    end

    test "parses bad DECIMAL column" do
      assert [["pi"]] = TypeParser.parse_rows(%{"COL_NAME" => :float}, ['COL_NAME'], [{"pi"}])
    end

    test "parses BOOLEAN column" do
      assert [[true, false]] =
               TypeParser.parse_rows(%{"COL_1" => :boolean, "COL_2" => :boolean}, ['COL_1', 'COL_2'], [{true, false}])
    end

    test "parses BOOLEAN as string column" do
      assert [[true, false]] =
               TypeParser.parse_rows(%{"COL_1" => :boolean, "COL_2" => :boolean}, ['COL_1', 'COL_2'], [
                 {"true", "false"}
               ])
    end

    test "parses DATE column" do
      assert [[~D[2015-01-13]]] = TypeParser.parse_rows(%{"COL_NAME" => :date}, ['COL_NAME'], [{"2015-01-13"}])
    end

    test "parses TIME column" do
      assert [[~T[13:00:07]]] = TypeParser.parse_rows(%{"COL_NAME" => :time}, ['COL_NAME'], [{"13:00:07"}])
    end

    test "parses DATETIME column" do
      assert [[~N[2015-01-13 13:00:07]]] =
               TypeParser.parse_rows(%{"COL_NAME" => :datetime}, ['COL_NAME'], [{{{2015, 1, 13}, {13, 0, 7}}}])
    end

    test "parses DATETIME as string column" do
      assert [[~N[2022-05-07 00:24:26.263]]] =
               TypeParser.parse_rows(%{"COL_NAME" => :datetime}, ['COL_NAME'], [{"2022-05-07T00:24:26.263"}])
    end

    test "parses TIMESTAMP column" do
      assert [[~N[2015-01-13 13:00:07]]] =
               TypeParser.parse_rows(%{"COL_NAME" => :datetime}, ['COL_NAME'], [{{{2015, 1, 13}, {13, 0, 7}}}])
    end

    test "parses TIMESTAMP_LTZ column" do
      assert [[~N[2015-01-13 13:00:07]]] =
               TypeParser.parse_rows(%{"COL_NAME" => :datetime}, ['COL_NAME'], [{{{2015, 1, 13}, {13, 0, 7}}}])
    end

    test "parses TIMESTAMP_NTZ column" do
      assert [[~N[2015-01-13 13:00:07]]] =
               TypeParser.parse_rows(%{"COL_NAME" => :datetime}, ['COL_NAME'], [{{{2015, 1, 13}, {13, 0, 7}}}])
    end

    test "parses TIMESTAMP_TZ column" do
      assert [[~N[2015-01-13 12:00:07]]] =
               TypeParser.parse_rows(%{"COL_NAME" => :datetime}, ['COL_NAME'], [{{{2015, 1, 13}, {12, 0, 7}}}])
    end

    test "parses TIMESTAMP_TZ as iso8601 string column" do
      assert [[~U[2022-05-07 00:24:26.263318Z]]] =
               TypeParser.parse_rows(%{"COL_NAME" => :datetime}, ['COL_NAME'], [{"2022-05-07T00:24:26.263318Z"}])
    end

    test "parses ARRAY column" do
      assert [[[1, "test", false]]] =
               TypeParser.parse_rows(%{"COL_NAME" => :array}, ['COL_NAME'], [{"[1, \"test\", false]"}])
    end

    test "parses empty ARRAY column" do
      assert [[[]]] = TypeParser.parse_rows(%{"COL_NAME" => :array}, ['COL_NAME'], [{"[]"}])
    end

    test "parses null ARRAY column" do
      assert [[[]]] = TypeParser.parse_rows(%{"COL_NAME" => :array}, ['COL_NAME'], [{:null}])
    end

    test "parses OBJECT column" do
      assert [[%{"key1" => 2, "key2" => "two"}]] =
               TypeParser.parse_rows(%{"COL_NAME" => :json}, ['COL_NAME'], [{~s<{"key1" : 2, "key2" : "two"}>}])
    end

    test "parses empty OBJECT column" do
      assert [[%{}]] = TypeParser.parse_rows(%{"COL_NAME" => :json}, ['COL_NAME'], [{"{}"}])
    end

    test "parses null OBJECT column" do
      assert [[%{}]] = TypeParser.parse_rows(%{"COL_NAME" => :json}, ['COL_NAME'], [{:null}])
    end

    test "parses VARIANT column when JSON" do
      assert [[%{"key1" => 2, "key2" => "two"}]] =
               TypeParser.parse_rows(%{"COL_NAME" => :variant}, ['COL_NAME'], [{~s<{"key1" : 2, "key2" : "two"}>}])
    end

    test "parses empty VARIANT column when JSON" do
      assert [[%{}]] = TypeParser.parse_rows(%{"COL_NAME" => :variant}, ['COL_NAME'], [{"{}"}])
    end

    test "parses null VARIANT column" do
      assert [[:null]] = TypeParser.parse_rows(%{"COL_NAME" => :variant}, ['COL_NAME'], [{:null}])
    end

    test "parses other stuff VARIANT column" do
      assert [["<xml>stuff</xml>"]] =
               TypeParser.parse_rows(%{"COL_NAME" => :variant}, ['COL_NAME'], [{"<xml>stuff</xml>"}])
    end

    test "parses UNKNOWN type column" do
      assert [["stuff"]] = TypeParser.parse_rows(%{"COL_NAME" => :unknown}, ['COL_NAME'], [{"stuff"}])
    end
  end

  describe "type parsing" do
    @describetag skip_ci: true

    @table "SNOWPACK.PUBLIC.TYPES_TABLE"
    @query "SELECT * from #{@table} LIMIT 1;"

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
