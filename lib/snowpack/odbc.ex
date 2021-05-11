defmodule Snowpack.ODBC do
  @moduledoc """
  Adapter to Erlang's `:odbc` module.

  This module is a GenServer that handles communication between Elixir
  and Erlang's `:odbc` module.

  It is used by `Snowpack.Protocol` and should not generally be
  accessed directly.
  """

  use GenServer

  alias Snowpack.Error

  require Logger

  @timeout :timer.seconds(60)
  @begin_transaction 'begin transaction;'
  @last_query_id 'SELECT LAST_QUERY_ID() as query_id;'
  @close_transaction 'commit;'

  @data_types [
    {~r/NUMBER\([0-9]+,0\)/, :integer},
    {~r/DECIMAL\([0-9]+,0\)/, :integer},
    {~r/NUMERIC\([0-9]+,0\)/, :integer},
    {~r/INT\([0-9]+,0\)/, :integer},
    {~r/INTEGER\([0-9]+,0\)/, :integer},
    {~r/BIGINT\([0-9]+,0\)/, :integer},
    {~r/SMALLINT\([0-9]+,0\)/, :integer},
    {~r/NUMBER\([0-9]+,[1-9]+\)/, :float},
    {~r/DECIMAL\([0-9]+,[1-9]+\)/, :float},
    {~r/NUMERIC\([0-9]+,[1-9]+\)/, :float},
    {~r/INT\([0-9]+,[1-9]+\)/, :float},
    {~r/INTEGER\([0-9]+,[1-9]+\)/, :float},
    {~r/BIGINT\([0-9]+,[1-9]+\)/, :float},
    {~r/SMALLINT\([0-9]+,[1-9]+\)/, :float},
    {~r/FLOAT/, :float},
    {~r/DOUBLE/, :float},
    {~r/REAL/, :float},
    {~r/DATETIME/, :datetime},
    {~r/TIMESTAMP/, :datetime},
    {~r/DATE/, :date},
    {~r/TIME/, :time},
    {~r/OBJECT/, :json},
    {~r/ARRAY/, :json}
  ]

  ## Public API

  @doc """
  Starts the connection process to the ODBC driver.

  `conn_str` should be a connection string in the format required by your ODBC driver.
  `opts` will be passed verbatim to `:odbc.connect/2`.
  """
  @spec start_link(binary(), Keyword.t()) :: {:ok, pid()}
  def start_link(conn_str, opts) do
    GenServer.start_link(__MODULE__, [{:conn_str, to_charlist(conn_str)} | opts])
  end

  @doc """
  Sends a parametrized query to the ODBC driver.

  Interface to `:odbc.param_query/3`.See
  [Erlang's ODBC guide](http://erlang.org/doc/apps/odbc/getting_started.html)
  for usage details and examples.

  `pid` is the `:odbc` process id
  `statement` is the SQL query string
  `params` are the parameters to send with the SQL query
  `opts` are options to be passed on to `:odbc`
  """
  @spec query(pid(), iodata(), Keyword.t(), Keyword.t()) ::
          {:selected, [binary()], [tuple()]}
          | {:updated, non_neg_integer()}
          | {:error, Error.t()}
  def query(pid, statement, params, opts) do
    if Process.alive?(pid) do
      statement = IO.iodata_to_binary(statement)

      GenServer.call(
        pid,
        {:query, %{statement: statement, params: params}},
        Keyword.get(opts, :timeout, @timeout)
      )
    else
      {:error, %Error{message: :no_connection}}
    end
  end

  @doc """
  Describes the given table.
  """
  @spec describe(pid(), iodata()) ::
          {:selected, [binary()], [tuple()]}
          | {:error, Error.t()}
  def describe(pid, table) do
    if Process.alive?(pid) do
      GenServer.call(pid, {:describe, table})
    else
      {:error, %Error{message: :no_connection}}
    end
  end

  @spec describe_result(pid(), iodata()) ::
          {:selected, [binary()], [tuple()]}
          | {:error, Error.t()}
  def describe_result(pid, query_id) do
    if Process.alive?(pid) do
      GenServer.call(pid, {:describe_result, query_id})
    else
      {:error, %Error{message: :no_connection}}
    end
  end

  @doc """
  Disconnects from the ODBC driver.

  `pid` is the `:odbc` process id
  """
  @spec disconnect(pid()) :: :ok
  def disconnect(pid) do
    GenServer.stop(pid, :normal)
  end

  ## GenServer callbacks

  @spec init(keyword) :: {:ok, any}
  def init(opts) do
    send(self(), {:start, opts})
    {:ok, %{backoff: :backoff.init(2, 60), state: :not_connected}}
  end

  def handle_call({:query, _query}, _from, %{state: :not_connected} = state) do
    {:reply, {:error, :not_connected}, state}
  end

  def handle_call(
        {:query, %{statement: statement, params: params}},
        _from,
        %{pid: pid} = state
      ) do
    :odbc.sql_query(pid, @begin_transaction)

    case :odbc.param_query(pid, to_charlist(statement), params) do
      {:error, reason} ->
        error = Error.exception(reason)
        Logger.warn("Unable to execute query: #{error.message}")

        :odbc.sql_query(pid, @close_transaction)

        {:reply, {:error, error}, state}

      result ->
        {:selected, _, query_id} = :odbc.sql_query(pid, @last_query_id)

        :odbc.sql_query(pid, @close_transaction)

        {:reply, Tuple.append(result, query_id), state}
    end
  end

  @spec handle_call(request :: term(), term(), state :: term()) :: term()
  def handle_call({:describe, table}, _from, %{pid: pid} = state) do
    case :odbc.describe_table(pid, to_charlist(table)) do
      {:error, reason} ->
        error = Error.exception(reason)
        Logger.warn("Unable to describe #{table}: #{error.message}")

        {:reply, {:error, error}, state}

      result ->
        {:reply, result, state}
    end
  end

  @spec handle_call(request :: term(), term(), state :: term()) :: term()
  def handle_call({:describe_result, query_id}, _from, %{pid: pid} = state) do
    case :odbc.sql_query(pid, to_charlist("DESCRIBE RESULT '#{query_id}'")) do
      {:error, reason} ->
        error = Error.exception(reason)
        Logger.warn("Unable to describe #{query_id}: #{error.message}")

        {:reply, {:error, error}, state}

      result ->
        # parse name, type
        {:reply, build_type_tuples(result), state}
    end
  end

  @spec terminate(term(), state :: term()) :: term()
  def terminate(_reason, %{state: :not_connected} = _state), do: :ok

  def terminate(_reason, %{pid: pid} = _state) do
    :odbc.disconnect(pid)
  end

  @spec handle_info(msg :: :timeout | term(), state :: term()) :: term()
  def handle_info({:start, opts}, %{backoff: backoff} = _state) do
    connect_opts =
      opts
      |> Keyword.delete_first(:conn_str)
      |> Keyword.put_new(:auto_commit, :on)
      |> Keyword.put_new(:binary_strings, :on)
      |> Keyword.put_new(:tuple_row, :on)
      |> Keyword.put_new(:extended_errors, :on)

    case :odbc.connect(opts[:conn_str], connect_opts) do
      {:ok, pid} ->
        {:noreply, %{pid: pid, backoff: :backoff.succeed(backoff), state: :connected}}

      {:error, reason} ->
        error = Error.exception(reason)

        Logger.warn("Unable to connect to snowflake: #{error.message}")

        Process.send_after(
          self(),
          {:start, opts},
          backoff |> :backoff.get() |> :timer.seconds()
        )

        {_, new_backoff} = :backoff.fail(backoff)
        {:noreply, %{backoff: new_backoff, state: :not_connected}}
    end
  end

  defp build_type_tuples({_, columns, rows}) do
    index_of_name =
      Enum.find_index(columns, fn element ->
        List.to_string(element) |> String.downcase() |> String.equivalent?("name")
      end)

    index_of_type =
      Enum.find_index(columns, fn element ->
        List.to_string(element) |> String.downcase() |> String.equivalent?("type")
      end)

    Enum.map(rows, fn row ->
      {_, type} =
        Enum.find(@data_types, {nil, :default}, fn {reg, type} ->
          String.match?(elem(row, index_of_type), reg)
        end)

      {elem(row, index_of_name), type}
    end)
  end
end
