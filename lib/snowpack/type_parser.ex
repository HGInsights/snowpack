defmodule Snowpack.TypeParser do
  @moduledoc """
  Parser for table column data types.
  """

  require Logger

  @type column_types :: map()
  @type columns :: list(charlist())
  @type row :: tuple()
  @type rows :: list(row())

  @type result_row :: list(any())
  @type result_rows :: list(result_row())

  @spec parse_rows(column_types(), columns(), rows()) :: result_rows()
  def parse_rows(column_types, queried_columns, rows) do
    parse(column_types, queried_columns, rows)
  end

  defp parse(column_types, queried_columns, rows) do
    types =
      queried_columns
      |> Enum.map(&List.to_string/1)
      |> Enum.map(&Map.get(column_types, &1))

    rows
    |> Enum.map(&Tuple.to_list/1)
    |> Enum.map(&Enum.zip(types, &1))
    |> Enum.map(&parse/1)
  end

  defp parse([]), do: []
  defp parse([head | tail]), do: [parse(head) | parse(tail)]

  defp parse({:time, data}), do: DateTimeParser.parse_time!(data)

  defp parse({:date, data}), do: DateTimeParser.parse_date!(data)

  defp parse({:datetime, {{_year, _month, _day}, {_hour, _minute, _second}} = data}),
    do: NaiveDateTime.from_erl!(data)

  defp parse({:datetime, data}), do: DateTimeParser.parse_datetime!(data)

  defp parse({:float, data}) when is_float(data), do: data

  defp parse({:float, data}) when is_binary(data) do
    case Float.parse(data) do
      {float, _rest} -> Decimal.from_float(float)
      :error -> return_raw(:float, data, :float_parse_error)
    end
  end

  defp parse({:integer, data}) when is_integer(data), do: data
  defp parse({:integer, data}) when is_binary(data), do: String.to_integer(data)

  defp parse({:boolean, data}) when is_boolean(data), do: data
  defp parse({:boolean, data}) when is_binary(data), do: "true" == data

  defp parse({:array, :null}), do: []
  defp parse({:array, data}), do: Jason.decode!(data)

  defp parse({:json, :null}), do: %{}
  defp parse({:json, data}), do: Jason.decode!(data)

  defp parse({:variant, :null}), do: :null

  defp parse({:variant, data}) do
    case Jason.decode(data) do
      {:ok, json} -> json
      {:error, _error} -> data
    end
  end

  defp parse({:default, data}), do: data

  defp parse({type, data}) do
    Logger.warn("TypeParser.parse/1: unsupported type '#{type}', data: #{inspect(data)}")
    data
  end

  defp return_raw(type, data, error) do
    Logger.warn("TypeParser.parse/1: failed decode of '#{type}' type: #{error}")
    data
  end
end
