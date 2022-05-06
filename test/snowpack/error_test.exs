defmodule Snowpack.ErrorTest do
  use ExUnit.Case, async: true

  alias Snowpack.Error

  describe "exception/1" do
    test "from a simple message" do
      assert %Snowpack.Error{
               message: "bad stuff!",
               odbc_code: nil,
               native_code: nil
             } = Error.exception("bad stuff!")
    end

    test "from codes + reason" do
      assert %Snowpack.Error{
               message: "bad | ODBC_CODE 123 | SNOWFLAKE_CODE 456",
               odbc_code: "123",
               native_code: "456"
             } = Error.exception({"123", "456", :bad})
    end

    test "connection_exception" do
      assert %Snowpack.Error{
               message: "bad | ODBC_CODE 08004 | SNOWFLAKE_CODE 333",
               native_code: "333",
               odbc_code: :connection_exception
             } = Error.exception({"08004", "333", :bad})
    end
  end
end
