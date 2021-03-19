# defmodule QueryTest do
#   use ExUnit.Case, async: true

#   import Snowpack.TestHelper

#   setup _context do
#     {:ok, pid} = Snowpack.start_link(key_pair_opts())

#     {:ok, [pid: pid]}
#   end

#   test "iodata", context do
#     assert [[123]] = query(["S", ?E, ["LEC" | "T"], " ", '123'], [])
#   end

#   test "decode basic types", context do
#     assert [[nil]] = query("SELECT NULL", [])
#     assert [[true, false]] = query("SELECT true, false", [])
#     assert [["e"]] = query("SELECT 'e'::char", [])
#     assert [["ẽ"]] = query("SELECT 'ẽ'::char", [])
#     assert [[42]] = query("SELECT 42", [])
#     assert [[42.0]] = query("SELECT 42::float", [])
#     assert [[:NaN]] = query("SELECT 'NaN'::float", [])
#     assert [[:inf]] = query("SELECT 'inf'::float", [])
#     assert [[:"-inf"]] = query("SELECT '-inf'::float", [])
#     assert [["ẽric"]] = query("SELECT 'ẽric'", [])
#     assert [["ẽric"]] = query("SELECT 'ẽric'::varchar", [])
#     assert [[<<1, 2, 3>>]] = query("SELECT '\\001\\002\\003'::bytea", [])
#   end
# end
