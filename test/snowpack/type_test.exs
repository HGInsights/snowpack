defmodule Snowpack.TypeTest do
  use ExUnit.Case, async: false

  # import Snowpack.TestHelper

  alias Snowpack.Type

  describe "encode/2" do
    test "boolean" do
      assert {:sql_bit, [true]} = Type.encode(true, [])
      assert {:sql_bit, [false]} = Type.encode(false, [])
    end

    test "date" do
      assert {{:sql_varchar, 10}, ["2022-03-13"]} = Type.encode(~D[2022-03-13], [])

      assert {{:sql_varchar, 10}, ["2022-03-13"]} = Type.encode(Date.to_erl(~D[2022-03-13]), [])
    end

    test "time" do
      assert {{:sql_varchar, 8}, ["13:00:07"]} = Type.encode(~T[13:00:07], [])
      assert {{:sql_varchar, 12}, ["13:00:07.123"]} = Type.encode(~T[13:00:07.123], [])

      assert {{:sql_varchar, 8}, ["13:00:07"]} = Type.encode({13, 0, 7, 0}, [])
      assert {{:sql_varchar, 15}, ["13:00:07.123000"]} = Type.encode({13, 0, 7, 123_000}, [])
    end

    test "datetime" do
      assert {{:sql_varchar, 24}, ["2015-01-13T13:00:07.123Z"]} = Type.encode(~U[2015-01-13T13:00:07.123Z], [])
      assert {{:sql_varchar, 19}, ["2015-01-13T13:00:07"]} = Type.encode(~N[2015-01-13T13:00:07], [])
      assert {{:sql_varchar, 23}, ["2015-01-13T13:00:07.123"]} = Type.encode(~N[2015-01-13T13:00:07.123], [])

      assert {{:sql_varchar, 19}, ["2015-01-13T13:00:07"]} =
               Type.encode(NaiveDateTime.to_erl(~N[2015-01-13T13:00:07]), [])

      assert {{:sql_varchar, 26}, ["2015-01-13T13:00:07.123000"]} =
               Type.encode({{2015, 1, 13}, {13, 0, 7, 123_000}}, [])
    end

    test "integer" do
      assert {:sql_integer, [345]} = Type.encode(345, [])
      assert {{:sql_varchar, 10}, ["1234567890"]} = Type.encode(1_234_567_890, [])
    end

    test "float" do
      assert {{:sql_varchar, 5}, ["34.57"]} = Type.encode(34.57, [])
    end

    test "decimal" do
      assert {{:sql_decimal, 28, 1}, ["33"]} = Type.encode(Decimal.new(33), [])
      assert {{:sql_decimal, 28, 1}, ["33.45234"]} = Type.encode(Decimal.new("33.45234"), [])
    end

    test "varchar" do
      assert {{:sql_varchar, 12}, ["some strings"]} = Type.encode("some strings", [])
    end

    test "null" do
      assert {:sql_integer, [:null]} = Type.encode(nil, [])
    end

    test "unknown" do
      assert_raise Snowpack.Error, fn ->
        Type.encode(%{bad: :stuff}, [])
      end
    end
  end

  describe "decode/2" do
    test "null" do
      assert Type.decode(:null, []) == nil
    end

    test "boolean" do
      assert Type.decode(true, []) == true
      assert Type.decode(false, []) == false
    end

    test "integer" do
      assert Type.decode(543, []) == 543
      assert Type.decode("543", []) == 543
    end

    test "float" do
      assert Type.decode(543.89875, []) == 543.89875
    end

    test "date, time, datetime" do
      assert Type.decode({{2015, 1, 13}, {13, 0, 7}}, []) == ~N[2015-01-13 13:00:07]
      assert Type.decode({{2015, 1, 54}, {13, 0, 7}}, []) == {{2015, 1, 54}, {13, 0, 7}}

      assert Type.decode("2015-01-13T13:00:07", []) == ~N[2015-01-13 13:00:07]
      assert Type.decode("2022-05-07T21:46:44.146219Z", []) == ~U[2022-05-07 21:46:44.146219Z]

      assert Type.decode("2022-05-07", []) == ~D[2022-05-07]

      assert Type.decode("21:46:44.146219Z", []) == ~T[21:46:44.146219]
    end

    test "failure to decode erl datetime passed original value through" do
      assert Type.decode({{2015, 1, 54}, {13, 0, 7}}, []) == {{2015, 1, 54}, {13, 0, 7}}
    end
  end
end
