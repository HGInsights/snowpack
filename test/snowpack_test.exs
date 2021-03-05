defmodule SnowpackTest do
  use ExUnit.Case
  doctest Snowpack

  test "greets the world" do
    assert Snowpack.hello() == :world
  end
end
