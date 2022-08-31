defmodule Snowpack do
  @external_resource "README.md"

  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  use Retry

  require Logger

  # The amount of time in milliseconds between heartbeats
  # that will be sent to the server (default: 5 min)
  @default_session_keepalive :timer.minutes(5)

  @type conn() :: DBConnection.conn()

  @type snowflake_conn_option() ::
          {:dsn, String.t()}
          | {:driver, String.t()}
          | {:server, String.t()}
          | {:role, String.t()}
          | {:warehouse, String.t()}
          | {:database, String.t()}
          | {:schema, String.t()}
          | {:uid, String.t()}
          | {:pwd, String.t()}
          | {:authenticator, String.t()}
          | {:token, String.t()}
          | {:priv_key_file, String.t()}
          | {:priv_key_file_pwd, String.t()}

  @type start_option() ::
          {:connection, snowflake_conn_option()}
          | DBConnection.start_option()

  @type option() :: DBConnection.option()

  @type query_option() ::
          {:parse_results, boolean()}
          | DBConnection.option()

  defmacrop is_iodata(data) do
    quote do
      is_list(unquote(data)) or is_binary(unquote(data))
    end
  end

  @doc """
  Returns a supervisor child specification for a DBConnection pool.
  """
  @spec child_spec([start_option()]) :: :supervisor.child_spec()
  def child_spec(opts) do
    DBConnection.child_spec(Snowpack.Protocol, opts)
  end

  defmodule DBConnectionListener do
    require Logger

    use GenServer

    def init(stack) when is_list(stack) do
      {:ok, stack}
    end

    def start_link() do
      Logger.info("Booting up")
      GenServer.start_link(__MODULE__, [], name: {:global, "db_connection_listener"})
    end

    def handle_call(:read_state, _from, state) do
      Logger.info("Handling call: here is the state: #{inspect(state)}")

      {:reply, state, state}
    end

    def handle_info(msg, state) do
      Logger.info("Handling the info! UPDATE, here is the msg: #{inspect(msg)} and here is the state: #{inspect(state)}")

      {:noreply, [msg | state]}
    end
  end

  @doc """
  Starts the connection process and connects to Snowflake.

  ## Options

  ### Snowflake Connection Options

  See: https://docs.snowflake.com/en/user-guide/odbc-parameters.html#required-connection-parameters

  * `:connection`

    * `:dsn` - Specifies the name of your DSN

    * `:driver` - Snowflake ODBC driver path

    * `:server` - Specifies the hostname for your account

    * `:role` - Specifies the default role to use for sessions initiated by the driver

    * `:warehouse` - Specifies the default warehouse to use for sessions initiated by the driver

    * `:database` - Specifies the default database to use for sessions initiated by the driver

    * `:schema` - Specifies the default schema to use for sessions initiated by the driver (default: `public`)

    * `:uid` - Specifies the login name of the Snowflake user to authenticate

    * `:pwd` - A password is required to connect to Snowflake

    * `:authenticator` - Specifies the authenticator to use for verifying user login credentials

    * `:token` - Specifies the token to use for token based authentication

    * `:priv_key_file` - Specifies the local path to the private key file

  ### DBConnection Options

  The given options are passed down to DBConnection, some of the most commonly used ones are
  documented below:

    * `:after_connect` - A function to run after the connection has been established, either a
      1-arity fun, a `{module, function, args}` tuple, or `nil` (default: `nil`)

    * `:pool` - The pool module to use, defaults to built-in pool provided by DBconnection

    * `:pool_size` - The size of the pool

  See `DBConnection.start_link/2` for more information and a full list of available options.

  ## Examples

  Start connection using basic User / Pass configuration:

      iex> {:ok, pid} = Snowpack.start_link(connection: [server: "account-id.snowflakecomputing.com", uid: "USER", pwd: "PASS"])
      {:ok, #PID<0.69.0>}

  Start connection using DNS configuration:

      iex> {:ok, pid} = Snowpack.start_link(connection: [dsn: "snowflake"])
      {:ok, #PID<0.69.0>}

  Run a query after connection has been established:

      iex> {:ok, pid} = Snowpack.start_link(connection: [dsn: "snowflake"], after_connect: &Snowpack.query!(&1, "SET time_zone = '+00:00'"))
      {:ok, #PID<0.69.0>}

  """
  @spec start_link([start_option()]) :: {:ok, pid()} | {:error, Snowpack.Error.t()}
  def start_link(opts) do
    opts = Keyword.put_new(:idle_interval, @default_session_keepalive)

    Logger.info("SHEEP Start DBConnection boot")
    {:ok, db_connection_listener} = DBConnectionListener.start_link()
    Logger.info("SHEEP Finish starting DBConnection boot")

    opts = Keyword.merge(opts, [connection_listeners: [db_connection_listener]])

    DBConnection.start_link(Snowpack.Protocol, opts)
  end

  @doc """
  Runs a query.

  ## Options

  Options are passed to `DBConnection.prepare/3`, see it's documentation for
  all available options.

  ## Additional Options

    * `:parse_results` - Wether or not to do type parsing on the results. Requires
    execution to be performed inside a transaction and an extra `DESCRIBE RESULT` to
    get the types of the columns in the result. Only important for `SELECT` queries. Default true.

  ## Examples

      iex> Snowpack.query(conn, "SELECT * FROM RECORDS")
      {:ok, %Snowpack.Result{}}

      iex> Snowpack.query(conn, "INSERT INTO RECORDS (ROW1, ROW2) VALUES(?, ?)", [1, 2], parse_results: false)

  """
  @spec query(conn, iodata, list, [query_option()]) ::
          {:ok, Snowpack.Result.t()} | {:error, Exception.t()}
  def query(conn, statement, params \\ [], options \\ []) when is_iodata(statement) do
    # retry after 50 ms 3 times
    retry with: [50] |> Stream.cycle() |> Stream.take(3) do
      Logger.debug("#{inspect(__MODULE__)} (#{inspect(conn)}) query: #{inspect(statement)}")

      case prepare_execute(conn, "", statement, params, options) do
        # retry only for connection_closed errors
        {:error, %Snowpack.Error{message: "connection_closed"} = error} -> {:error, error}
        # let other errors go through without a retry
        {:error, error} -> {:ok, {:error, error}}
        result -> result
      end
    after
      {:ok, _query, result} -> {:ok, result}
      {:ok, {:error, error}} -> {:error, error}
    else
      error -> error
    end
  end

  @doc """
  Runs a query.

  Returns `%Snowpack.Result{}` on success, or raises an exception if there was an error.

  See `query/4`.
  """
  @spec query!(conn, iodata, list, [query_option()]) :: Snowpack.Result.t()
  def query!(conn, statement, params \\ [], opts \\ []) do
    case query(conn, statement, params, opts) do
      {:ok, result} -> result
      {:error, exception} -> raise exception
    end
  end

  @doc """
  Prepares a query to be executed later.

  To execute the query, call `execute/4`. To close the query, call `close/3`.
  If a name is given, the name must be unique per query, as the name is cached
  but the statement isn't. If a new statement is given to an old name, the old
  statement will be the one effectively used.

  ## Options

  Options are passed to `DBConnection.prepare/3`, see it's documentation for
  all available options.

  ## Additional Options

    * `:parse_results` - Wether or not to do type parsing on the results. Requires
    execution to be performed inside a transaction and an extra `DESCRIBE RESULT` to
    get the types of the columns in the result. Only important for `SELECT` queries. Default true.

  ## Examples

      iex> {:ok, query} = Snowpack.prepare(conn, "", "SELECT ? * ?")
      iex> {:ok, %Snowpack.Result{rows: [row]}} = Snowpack.execute(conn, query, [2, 3])
      iex> row
      [6]

  """
  @spec prepare(conn(), iodata(), iodata(), [query_option()]) ::
          {:ok, Snowpack.Query.t()} | {:error, Exception.t()}
  def prepare(conn, name, statement, opts \\ []) when is_iodata(name) and is_iodata(statement) do
    query = %Snowpack.Query{name: name, statement: statement}
    DBConnection.prepare(conn, query, opts)
  end

  @doc """
  Prepares a query.

  Returns `%Snowpack.Query{}` on success, or raises an exception if there was an error.

  See `prepare/4`.
  """
  @spec prepare!(conn(), iodata(), iodata(), [query_option()]) :: Snowpack.Query.t()
  def prepare!(conn, name, statement, opts \\ []) when is_iodata(name) and is_iodata(statement) do
    query = %Snowpack.Query{name: name, statement: statement}
    DBConnection.prepare!(conn, query, opts)
  end

  @doc """
  Prepares and executes a query in a single step.

  ## Multiple results

  If a query returns multiple results (e.g. it's calling a procedure that returns multiple results)
  an error is raised. If a query may return multiple results it's recommended to use `stream/4` instead.

  ## Options

  Options are passed to `DBConnection.prepare_execute/4`, see it's documentation for
  all available options.

  ## Additional Options

    * `:parse_results` - Wether or not to do type parsing on the results. Requires
    execution to be performed inside a transaction and an extra `DESCRIBE RESULT` to
    get the types of the columns in the result. Only important for `SELECT` queries. Default true.

  ## Examples

      iex> {:ok, _query, %Snowpack.Result{rows: [row]}} = Snowpack.prepare_execute(conn, "", "SELECT ? * ?", [2, 3])
      iex> row
      [6]

  """
  @spec prepare_execute(conn, iodata, iodata, list, keyword()) ::
          {:ok, Snowpack.Query.t(), Snowpack.Result.t()} | {:error, Exception.t()}
  def prepare_execute(conn, name, statement, params \\ [], opts \\ [])
      when is_iodata(name) and is_iodata(statement) do
    query = %Snowpack.Query{name: name, statement: statement}
    DBConnection.prepare_execute(conn, query, params, opts)
  end

  @doc """
  Prepares and executes a query in a single step.

  Returns `{%Snowpack.Query{}, %Snowpack.Result{}}` on success, or raises an exception if there was
  an error.

  See: `prepare_execute/5`.
  """
  @spec prepare_execute!(conn, iodata, iodata, list, [query_option()]) ::
          {Snowpack.Query.t(), Snowpack.Result.t()}
  def prepare_execute!(conn, name, statement, params \\ [], opts \\ [])
      when is_iodata(name) and is_iodata(statement) do
    query = %Snowpack.Query{name: name, statement: statement}
    DBConnection.prepare_execute!(conn, query, params, opts)
  end

  @doc """
  Executes a prepared query.

  ## Options

  Options are passed to `DBConnection.execute/4`, see it's documentation for
  all available options.

  ## Examples

      iex> {:ok, query} = Snowpack.prepare(conn, "", "SELECT ? * ?")
      iex> {:ok, %Snowpack.Result{rows: [row]}} = Snowpack.execute(conn, query, [2, 3])
      iex> row
      [6]

  """
  @spec execute(conn(), Snowpack.Query.t(), list(), [query_option()]) ::
          {:ok, Snowpack.Query.t(), Snowpack.Result.t()} | {:error, Exception.t()}
  defdelegate execute(conn, query, params, opts \\ []), to: DBConnection

  @doc """
  Executes a prepared query.

  Returns `%Snowpack.Result{}` on success, or raises an exception if there was an error.

  See: `execute/4`.
  """
  @spec execute!(conn(), Snowpack.Query.t(), list(), keyword()) :: Snowpack.Result.t()
  defdelegate execute!(conn, query, params, opts \\ []), to: DBConnection

  @doc """
  Closes a prepared query.

  Returns `:ok` on success, or raises an exception if there was an error.

  ## Options

  Options are passed to `DBConnection.close/3`, see it's documentation for
  all available options.
  """
  @spec close(conn(), Snowpack.Query.t(), [option()]) :: :ok | {:error, Exception.t()}
  def close(conn, %Snowpack.Query{} = query, opts \\ []) do
    case DBConnection.close(conn, query, opts) do
      {:ok, _} ->
        :ok

      # coveralls-ignore-start
      # handle_close is a noop. no db resources to free.
      error ->
        error
        # coveralls-ignore-stop
    end
  end

  @doc """
  Return the transaction status of a connection.
  """
  @spec status(conn(), opts :: Keyword.t()) :: DBConnection.status()
  def status(conn, opts \\ []) do
    DBConnection.status(conn, opts)
  end
end
