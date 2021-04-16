defmodule Snowpack.Protocol do
  @moduledoc """
  Implementation of `DBConnection` behaviour for `Snowpack.ODBC`.

  Handles translation of concepts to what ODBC expects and holds
  state for a connection.

  This module is not called directly, but rather through
  other `Snowpack` modules or `DBConnection` functions.
  """

  use DBConnection

  alias Snowpack.ODBC
  alias Snowpack.Result

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
  @type params :: [{:odbc.odbc_data_type(), :odbc.value()}]
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
    {status, message, new_state} = do_query(query, params, opts, state)
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

    case do_query(query, [], [], state) do
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

  defp do_query(query, params, opts, state) do
    case ODBC.query(state.pid, query.statement, params, opts) do
      {:error, %Snowpack.Error{odbc_code: :connection_exception} = reason} ->
        {:disconnect, reason, state}

      {:error, reason} ->
        {:error, reason, state}

      {:selected, columns, rows} ->
        rows =
          Snowpack.TypeParser.parse_rows(
            state.pid,
            query.statement,
            columns,
            rows
          )

        {:ok,
         %Result{
           columns: Enum.map(columns, &to_string(&1)),
           rows: rows,
           num_rows: Enum.count(rows)
         }, state}

      {:updated, num_rows} ->
        {:ok, %Result{num_rows: num_rows}, state}
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
