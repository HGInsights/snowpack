defmodule Snowpack.TypeParser do
  @moduledoc """
  Parser for table column data types.
  """

  alias Snowpack.TypeCache

  @spec parse_rows(pid(), binary, any, any) :: list
  def parse_rows(pid, statement, queried_columns, rows)
      when is_binary(statement) do
    statement = String.split(statement)
    parse_rows(pid, statement, queried_columns, rows)
  end

  @spec parse_rows(pid(), list(), any, any) :: list
  def parse_rows(pid, statement, queried_columns, rows)
      when is_list(statement) do
    case statement do
      ["INSERT INTO ", [34, table, 34] | _] ->
        table_columns = TypeCache.fetch_table_columns(pid, table)
        parse(table_columns, queried_columns, rows)

      ["UPDATE ", [34, table, 34] | _] ->
        table_columns = TypeCache.fetch_table_columns(pid, table)
        parse(table_columns, queried_columns, rows)

      ["DELETE" | tail] ->
        find_tables(pid, tail, queried_columns, rows)

      ["SELECT" | tail] ->
        find_tables(pid, tail, queried_columns, rows)

      ["UPDATE" | tail] ->
        find_tables(pid, tail, queried_columns, rows)
    end
  end

  defp find_tables(pid, tail, queried_columns, rows) do
    case build_table_list(tail, []) do
      [table] ->
        table_columns = TypeCache.fetch_table_columns(pid, table)
        parse(table_columns, queried_columns, rows)

      [] ->
        Enum.map(rows, &Tuple.to_list/1)

      table_list ->
        table_list
        |> Enum.reverse()
        |> Enum.map(&TypeCache.fetch_table_columns(pid, &1))
        |> parse_tables(queried_columns, rows)
    end
  end

  defp build_table_list([], tables), do: tables

  defp build_table_list(["FROM", "(SELECT" | tail], tables),
    do: build_table_list(tail, tables)

  defp build_table_list(["FROM", table | tail], tables),
    do: build_table_list(tail, [table | tables])

  defp build_table_list(["JOIN", table | tail], tables),
    do: build_table_list(tail, [table | tables])

  defp build_table_list([_ | tail], tables), do: build_table_list(tail, tables)

  defp parse_tables(tables, queried_columns, rows) do
    types =
      Enum.map(queried_columns, fn column ->
        tables
        |> Enum.map(&Map.get(&1, column))
        |> Enum.filter(& &1)
        |> Enum.sort()
        |> Enum.dedup()
      end)

    rows
    |> Enum.map(&Tuple.to_list/1)
    |> Enum.map(&Enum.zip(types, &1))
    |> Enum.map(&parse_and_select/1)
  end

  defp parse_and_select(row) do
    # credo:disable-for-lines:14 Credo.Check.Readability.SinglePipe
    parse(row)
    |> Enum.map(fn col ->
      col =
        col
        |> Enum.sort()
        |> Enum.dedup()

      if Enum.count(col) == 1 do
        List.first(col)
      else
        raise "unable to determine correct type of #{inspect(col)}"
      end
    end)
  end

  defp parse(table_columns, queried_columns, rows) do
    types = Enum.map(queried_columns, &Map.get(table_columns, &1))

    rows
    |> Enum.map(&Tuple.to_list/1)
    |> Enum.map(&Enum.zip(types, &1))
    |> Enum.map(&parse/1)
  end

  defp parse([]), do: []
  defp parse([head | tail]), do: [parse(head) | parse(tail)]

  defp parse({[] = _types, data}), do: List.wrap(data)

  defp parse({types, data}) when is_list(types) do
    Enum.map(types, fn type -> parse({type, data}) end)
  end

  defp parse({_type, :null}), do: :null

  defp parse({:sql_bigint, data}) when is_binary(data),
    do: String.to_integer(data)

  defp parse({:sql_integer, data}) when is_binary(data),
    do: String.to_integer(data)

  defp parse({{:sql_numeric, _, _}, data}) when is_binary(data) do
    {float, ""} = Float.parse(data)
    Decimal.from_float(float)
  end

  defp parse({{:sql_decimal, _, _}, data}) when is_binary(data) do
    {float, ""} = Float.parse(data)
    Decimal.from_float(float)
  end

  defp parse({_type, data}) do
    # {_type, data} |> IO.inspect(label: :parse)
    data
  end
end
