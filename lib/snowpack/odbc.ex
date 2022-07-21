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

  @default_query_timeout :timer.seconds(120)
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
    {~r/BOOLEAN/, :boolean},
    {~r/FLOAT/, :float},
    {~r/DOUBLE/, :float},
    {~r/REAL/, :float},
    {~r/DATETIME/, :datetime},
    {~r/TIMESTAMP/, :datetime},
    {~r/DATE/, :date},
    {~r/TIME/, :time},
    {~r/OBJECT/, :json},
    {~r/ARRAY/, :array},
    {~r/VARIANT/, :variant}
  ]

  ## Public API

  @doc """
  Starts the connection process to the ODBC driver.

  `conn_str` should be a connection string in the format required by your ODBC driver.
  `opts` will be passed verbatim to `:odbc.connect/2`.
  """
  @spec start_link(Keyword.t()) :: {:ok, pid()}
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @doc """
  Sends a parametrized query to the ODBC driver.

  Interface to `:odbc.param_query/3`.See
  [Erlang's ODBC guide](http://erlang.org/doc/apps/odbc/getting_started.html)
  for usage details and examples.

  * `pid` is the `:odbc` process id
  * `statement` is the SQL query string
  * `params` are the parameters to send with the SQL query
  * `opts` are options to be passed on to `:odbc`
    * `timeout` in millisecods (defaults to 2 minutes)
  * `with_query_id` runs query in transaction and selects LAST_QUERY_ID()
  """
  @spec query(pid(), iodata(), Keyword.t(), Keyword.t(), boolean()) ::
          {:selected, [binary()], [tuple()]}
          | {:selected, [binary()], [tuple()], [{binary()}]}
          | {:updated, non_neg_integer()}
          | {:error, Error.t()}
  def query(pid, statement, params, opts, with_query_id \\ false) do
    if Process.alive?(pid) do
      statement = IO.iodata_to_binary(statement)

      timeout = Keyword.get(opts, :timeout, @default_query_timeout)

      # call timeout is query timeout + 60s buffer
      call_timeout = timeout + :timer.seconds(60)

      GenServer.call(
        pid,
        {:query, %{statement: statement, params: params, with_query_id: with_query_id, timeout: timeout}},
        call_timeout
      )
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
  # TODO: figure out how to test this correctly
  # coveralls-ignore-start
  @spec disconnect(pid()) :: :ok
  def disconnect(pid) do
    GenServer.stop(pid, :normal)
  end

  # coveralls-ignore-stop

  ## GenServer callbacks

  @spec init(keyword) :: {:ok, any}
  def init(opts) do
    send(self(), {:start, opts})
    {:ok, %{backoff: :backoff.init(2, 60), state: :not_connected}}
  end

  @spec handle_call(request :: term(), term(), state :: term()) ::
          {:noreply, term()}
          | {:noreply, term(), :hibernate | :infinity | non_neg_integer() | {:continue, term()}}
          | {:reply, term(), term()}
          | {:stop, term(), term()}
          | {:reply, term(), term(), :hibernate | :infinity | non_neg_integer() | {:continue, term()}}
          | {:stop, term(), term(), term()}
  def handle_call({:query, _query}, _from, %{state: :not_connected} = state) do
    {:reply, {:error, :not_connected}, state}
  end

  def handle_call(
        {:query, %{statement: statement, params: params, with_query_id: false, timeout: timeout}},
        _from,
        %{pid: pid} = state
      ) do
    case :odbc.param_query(pid, :binary.bin_to_list(statement), params, timeout) do
      {:error, reason} ->
        error = Error.exception(reason)

        if is_erlang_odbc_no_data_found_bug?(error, statement) do
          {:reply, {:updated, :undefined}, state}
        else
          Logger.warn("Unable to execute query: #{error.message}")

          {:reply, {:error, error}, state}
        end

      result ->
        {:reply, result, state}
    end
  end

  def handle_call(
        {:query, %{statement: statement, params: params, with_query_id: true, timeout: timeout}},
        _from,
        %{pid: pid} = state
      ) do
    :odbc.sql_query(pid, @begin_transaction)

    case :odbc.param_query(pid, :binary.bin_to_list(statement), params, timeout) do
      {:error, reason} ->
        error = Error.exception(reason)

        if is_erlang_odbc_no_data_found_bug?(error, statement) do
          {:reply, {:updated, :undefined}, state}
        else
          Logger.warn("Unable to execute query: #{error.message}")

          :odbc.sql_query(pid, @close_transaction)

          {:reply, {:error, error}, state}
        end

      result ->
        case :odbc.sql_query(pid, @last_query_id) do
          {:selected, _, query_id} ->
            :odbc.sql_query(pid, @close_transaction)

            {:reply, Tuple.append(result, query_id), state}

          {:error, reason} ->
            error = Error.exception(reason)
            Logger.warn("Unable to execute query: #{error.message}")
            Logger.warn("Last query result: #{inspect(result)}")

            :odbc.sql_query(pid, @close_transaction)

            {:reply, {:error, error}, state}
        end
    end
  end

  def handle_call({:describe_result, query_id}, _from, %{pid: pid} = state) do
    case :odbc.sql_query(pid, :binary.bin_to_list("DESCRIBE RESULT '#{query_id}'")) do
      {:error, reason} ->
        # coveralls-ignore-start
        error = Error.exception(reason)
        Logger.warn("Unable to describe #{query_id}: #{error.message}")

        case error.odbc_code do
          "02000" ->
            Logger.warn("Query #{query_id} has expired.")
            {:reply, [], state}

          _ ->
            {:reply, {:error, error}, state}
        end

      # coveralls-ignore-stop

      result ->
        # parse name, type
        {:reply, build_type_tuples(result), state}
    end
  end

  @spec handle_info(msg :: :timeout | term(), state :: term()) ::
          {:noreply, term()}
          | {:noreply, term(), :hibernate | :infinity | non_neg_integer() | {:continue, term()}}
          | {:stop, term(), term()}
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
        # coveralls-ignore-start
        error = Error.exception(reason)

        Logger.warn("Unable to connect to snowflake: #{error.message}")

        Process.send_after(
          self(),
          {:start, opts},
          backoff |> :backoff.get() |> :timer.seconds()
        )

        {_, new_backoff} = :backoff.fail(backoff)
        {:noreply, %{backoff: new_backoff, state: :not_connected}}
        # coveralls-ignore-stop
    end
  end

  # TODO: figure out how to test this correctly
  # coveralls-ignore-start
  @spec terminate(term(), state :: term()) :: term()
  def terminate(_reason, %{state: :not_connected} = _state), do: :ok
  def terminate(_reason, %{pid: pid} = _state), do: :odbc.disconnect(pid)
  # coveralls-ignore-stop

  defp build_type_tuples({_, columns, rows}) do
    Enum.map(rows, fn row ->
      columns
      |> Enum.zip_reduce(Tuple.to_list(row), %{}, fn name, value, acc ->
        Map.put(acc, to_string(name), value)
      end)
      |> Kernel.then(&data_type_from_column_metadata/1)
    end)
  end

  defp data_type_from_column_metadata(%{"name" => name, "type" => col_type}) do
    {_, type} =
      Enum.find(@data_types, {nil, :default}, fn {reg, _type} ->
        String.match?(col_type, reg)
      end)

    {name, type}
  end

  defp is_erlang_odbc_no_data_found_bug?(%Error{message: message}, statement) do
    is_dml = statement =~ ~r/^(INSERT|UPDATE|DELETE)/i
    is_msg = message =~ "No SQL-driver information available."

    is_dml and is_msg
  end
end
