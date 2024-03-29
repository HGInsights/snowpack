defmodule Snowpack.TypeCache do
  @moduledoc """
  Cache for fetching and storing the table column types.
  """

  @cache :type_cache
  @cache_limit 1_000

  GenServer
  @spec child_spec(any) :: Supervisor.child_spec()
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  @spec start_link(any()) :: Supervisor.on_start()
  def start_link(_) do
    Mentat.start_link(name: @cache, limit: [size: @cache_limit])
  end

  @spec key_from_statement(statement :: binary()) :: binary()
  def key_from_statement(statement), do: :crypto.hash(:md5, statement)

  @spec get_column_types(statement :: binary()) :: {:ok, map()} | nil
  def get_column_types(statement) do
    key = key_from_statement(statement)

    case Mentat.get(@cache, key) do
      nil ->
        nil

      value ->
        {:ok, value}
    end
  end

  @spec fetch_column_types(pid :: pid(), query_id :: binary(), statement :: any()) ::
          {:ok, map()}
  def fetch_column_types(pid, query_id, statement) do
    key = key_from_statement(statement)

    columns =
      Mentat.fetch(@cache, key, fn _key ->
        {:commit, get_table_columns(pid, query_id)}
      end)

    {:ok, columns}
  end

  defp get_table_columns(pid, query_id) do
    pid
    |> Snowpack.ODBC.describe_result(query_id)
    |> Map.new()
  end
end
