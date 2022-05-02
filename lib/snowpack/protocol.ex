defmodule Snowpack.Protocol do
  @moduledoc """
  Implementation of `DBConnection` behaviour for `Snowpack.ODBC`.

  Handles translation of concepts to what ODBC expects and holds
  state for a connection.

  This module is not called directly, but rather through
  other `Snowpack` modules or `DBConnection` functions.
  """

  use DBConnection

  alias Snowpack.{ODBC, Result, Telemetry, TypeCache, TypeParser}

  defstruct pid: nil, snowflake: :idle, conn_opts: []

  @typedoc """
  Process state.

  Includes:

  * `:pid`: the pid of the ODBC process
  * `:snowflake`: the transaction state. Can be `:idle` (not in a transaction).
  * `:conn_opts`: the options used to set up the connection.
  """
  @type state :: %__MODULE__{
          pid: pid(),
          snowflake: :idle,
          conn_opts: Keyword.t()
        }

  @type opts :: Keyword.t()
  @type query :: Snowpack.Query.t()
  @type value :: :null | term()
  @type params :: [{atom(), [value()]}] | [{atom(), atom(), [value()]}]
  @type result :: Result.t()
  @type status :: :idle | :error

  @spec connect(opts) :: {:ok, state} | {:error, Exception.t()}
  def connect(opts) do
    conn_opts = Keyword.fetch!(opts, :connection)

    conn_str =
      Enum.reduce(conn_opts, "", fn {key, value}, acc ->
        acc <> "#{key}=#{value};"
      end)

    {:ok, pid} = ODBC.start_link(conn_str, opts)

    {:ok,
     %__MODULE__{
       pid: pid,
       conn_opts: opts,
       snowflake: :idle
     }}
  end

  @spec disconnect(err :: String.t() | Exception.t(), state) :: :ok
  def disconnect(_err, %{pid: pid} = _state) do
    :ok = ODBC.disconnect(pid)
  end

  @spec reconnect(opts, state) :: {:ok, state}
  def reconnect(new_opts, state) do
    disconnect("Reconnecting", state)
    connect(new_opts)
  end

  @spec checkout(state) ::
          {:ok, state}
          | {:disconnect, Exception.t(), state}
  def checkout(state) do
    {:ok, state}
  end

  @spec checkin(state) ::
          {:ok, state}
          | {:disconnect, Exception.t(), state}
  def checkin(state) do
    {:ok, state}
  end

  @spec handle_prepare(query, opts, state) ::
          {:ok, query, state}
          | {:error | :disconnect, Exception.t(), state}
  def handle_prepare(query, _opts, state) do
    {:ok, query, state}
  end

  @spec handle_execute(query, params, opts, state) ::
          {:ok, query(), result(), state}
          | {:error | :disconnect, Exception.t(), state}
  def handle_execute(query, params, opts, state) do
    {status, message, new_state} = _query(query, params, opts, state)
    execute_return(status, query, message, new_state, opts)
  end

  @spec handle_close(query, opts, state) :: {:ok, result, state}
  def handle_close(_query, _opts, state) do
    {:ok, %Result{}, state}
  end

  @spec ping(state :: any()) ::
          {:ok, new_state :: any()}
          | {:disconnect, Exception.t(), new_state :: any()}
  def ping(state) do
    query = %Snowpack.Query{name: "ping", statement: "SELECT /* snowpack:heartbeat */ 1;"}

    case _query(query, [], [], state) do
      {:ok, _, new_state} -> {:ok, new_state}
      {:error, reason, new_state} -> {:disconnect, reason, new_state}
      other -> other
    end
  end

  @spec handle_status(opts, state) :: {DBConnection.status(), state}
  def handle_status(_, %{snowflake: {status, _}} = s), do: {status, s}
  def handle_status(_, %{snowflake: status} = s), do: {status, s}

  # NOT IMPLEMENTED
  @spec handle_begin(opts, state) ::
          {:ok, result, state}
          | {status, state}
          | {:disconnect, Exception.t(), state}
  def handle_begin(_opts, _state) do
    throw("not implemeted")
  end

  @spec handle_commit(opts, state) ::
          {:ok, result, state}
          | {status, state}
          | {:disconnect, Exception.t(), state}
  def handle_commit(_opts, _state) do
    throw("not implemeted")
  end

  @spec handle_rollback(opts, state) ::
          {:ok, result(), state}
          | {status, state}
          | {:disconnect, Exception.t(), state}
  def handle_rollback(_opts, _state) do
    throw("not implemeted")
  end

  @spec handle_declare(any, any, any, any) :: none
  def handle_declare(_query, _params, _opts, _state) do
    throw("not implemeted")
  end

  @spec handle_first(any, any, any, any) :: none
  def handle_first(_query, _cursor, _opts, _state) do
    throw("not implemeted")
  end

  @spec handle_next(any, any, any, any) :: none
  def handle_next(_query, _cursor, _opts, _state) do
    throw("not implemeted")
  end

  @spec handle_deallocate(any, any, any, any) :: none
  def handle_deallocate(_query, _cursor, _opts, _state) do
    throw("not implemeted")
  end

  @spec handle_fetch(any, any, any, any) :: none
  def handle_fetch(_query, _cursor, _opts, _state) do
    throw("not implemeted")
  end

  defp _query(query, params, opts, state) do
    metadata = %{params: params, query: query.statement}

    start_time = Telemetry.start(:query, metadata)

    try do
      result = get_column_types(query, params, opts, state)

      case result do
        {:error, %Snowpack.Error{odbc_code: :connection_exception} = error} ->
          metadata = Map.put(metadata, :error, error)
          Telemetry.stop(:query, start_time, metadata)
          {:disconnect, error, state}

        {:error, error, _column_types} ->
          metadata = Map.put(metadata, :error, error)
          Telemetry.stop(:query, start_time, metadata)
          {:error, error, state}

        {:error, error} ->
          metadata = Map.put(metadata, :error, error)
          Telemetry.stop(:query, start_time, metadata)
          {:error, error, state}

        {:selected, columns, rows, %{column_types: column_types}} ->
          typed_rows = TypeParser.parse_rows(column_types, columns, rows)
          num_rows = Enum.count(typed_rows)

          metadata = Map.merge(metadata, %{result: :selected, num_rows: num_rows})

          Telemetry.stop(:query, start_time, metadata)

          {:ok,
           %Result{
             columns: Enum.map(columns, &to_string(&1)),
             rows: typed_rows,
             num_rows: num_rows
           }, state}

        {:updated, num_rows} ->
          metadata = Map.merge(metadata, %{result: :updated, num_rows: num_rows})
          Telemetry.stop(:query, start_time, metadata)
          {:ok, %Result{num_rows: num_rows}, state}

        {:updated, :undefined, [{_query_id}]} ->
          metadata = Map.merge(metadata, %{result: :updated, num_rows: 1})
          Telemetry.stop(:query, start_time, metadata)
          {:ok, %Result{num_rows: 1}, state}

        {:updated, num_rows, [{_query_id}]} ->
          metadata = Map.merge(metadata, %{result: :updated, num_rows: num_rows})
          Telemetry.stop(:query, start_time, metadata)
          {:ok, %Result{num_rows: num_rows}, state}
      end
    catch
      kind, error ->
        Telemetry.exception(:query, start_time, kind, error, __STACKTRACE__, metadata)

        :erlang.raise(kind, error, __STACKTRACE__)
    end
  end

  defp get_column_types(query, params, opts, state) do
    case TypeCache.get_column_types(query.statement) do
      {:ok, column_types} ->
        query_result = ODBC.query(state.pid, query.statement, params, opts)
        Tuple.append(query_result, %{column_types: column_types})

      nil ->
        with {:selected, columns, rows, [{query_id}]} <-
               ODBC.query(state.pid, query.statement, params, opts, true),
             {:ok, column_types} <-
               TypeCache.fetch_column_types(state.pid, query_id, to_string(query.statement)) do
          {:selected, columns, rows, %{column_types: column_types}}
        end
    end
  end

  defp execute_return(status, _query, message, state, mode: _savepoint) do
    {status, message, state}
  end

  defp execute_return(status, query, message, state, _opts) do
    case status do
      :ok -> {status, query, message, state}
      _ -> {status, message, state}
    end
  end
end
