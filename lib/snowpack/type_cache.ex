defmodule Snowpack.TypeCache do
  @moduledoc """
  Cache of fetching and storing the table column types.
  """

  @spec fetch_table_columns(pid :: pid(), table :: binary()) :: {:ok, map()}
  def fetch_table_columns(pid, table) do
    {table, columns} = get(table)

    if columns do
      columns
    else
      get_and_store_table_columns(pid, table)
    end
  end

  defp get_and_store_table_columns(pid, table) do
    pid
    |> Snowpack.ODBC.describe(table)
    |> elem(1)
    |> Map.new()
    |> put(table)
  end

  defp get(table) do
    :persistent_term.get({__MODULE__, table}, {table, nil})
  end

  defp put(columns, table) do
    :persistent_term.put({__MODULE__, table}, {table, columns})
    columns
  end
end
