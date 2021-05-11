defmodule Snowpack.TypeCache do
  @moduledoc """
  Cache of fetching and storing the table column types.
  """

  @spec fetch_result_columns(pid :: pid(), query_id :: binary(), statement :: any()) ::
          {:ok, map()}
  def fetch_result_columns(pid, query_id, statement) do
    statement_hash = :crypto.hash(:md5, statement)
    {statement_hash, columns} = get(statement_hash)

    if columns do
      columns
    else
      get_and_store_table_columns(pid, query_id, statement_hash)
    end
  end

  defp get_and_store_table_columns(pid, query_id, statement_hash) do
    pid
    |> Snowpack.ODBC.describe_result(query_id)
    |> Map.new()
    |> put(statement_hash)
  end

  defp get(statement_hash) do
    :persistent_term.get({__MODULE__, statement_hash}, {statement_hash, nil})
  end

  defp put(columns, statement_hash) do
    :persistent_term.put({__MODULE__, statement_hash}, {statement_hash, columns})
    columns
  end
end
