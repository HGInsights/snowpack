defmodule Snowpack.QueryTest do
  use ExUnit.Case, async: true

  alias Snowpack.Query

  test "to_string" do
    query = %Query{name: "test", statement: "select 3;"}

    assert to_string(query) == "select 3;"
  end
end
