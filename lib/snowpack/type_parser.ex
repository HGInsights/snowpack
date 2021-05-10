defmodule Snowpack.TypeParser do
  @moduledoc """
  Parser for table column data types.
  """

  alias Snowpack.TypeCache

  @spec parse_rows(pid(), binary, any, any, any) :: list
  def parse_rows(pid, statement, queried_columns, rows, query_id)
      when is_binary(statement) do
    statement = String.split(statement)
    parse_rows(pid, statement, queried_columns, rows, query_id)
  end

  @spec parse_rows(pid(), list(), any, any, any) :: list
  def parse_rows(pid, statement, queried_columns, rows, query_id)
      when is_list(statement) do
    result_columns = TypeCache.fetch_result_columns(pid, query_id, List.to_string(statement))
    parse(result_columns, queried_columns, rows)
  end

  defp parse(result_columns, queried_columns, rows) do
    types = Enum.map(queried_columns, &Map.get(result_columns, &1))

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

  defp parse({:time, data}), do: DateTimeParser.parse_time!(data)

  defp parse({:date, data}), do: DateTimeParser.parse_date!(data)

  defp parse({:datetime, data}), do: DateTimeParser.parse_datetime!(data)

  defp parse({:float, data}) do
    {float, ""} = Float.parse(data)
    Decimal.from_float(float)
  end

  defp parse({:integer, data}), do: String.to_integer(data)

  defp parse({:json, data}), do: Poison.decode!(data)

  defp parse({_, data}) do
    data
  end

  # TODO: support other Snowflake data types
  # https://docs.snowflake.com/en/user-guide/odbc-api.html#custom-sql-data-types
  #   define SQL_SF_VARIANT       2005
end
