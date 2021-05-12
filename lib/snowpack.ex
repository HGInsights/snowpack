defmodule Snowpack do
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  # The amount of time in milliseconds that a heartbeat
  # will be sent to the server (default: 5 min)
  @default_session_keepalive 5 * 60 * 1000

  @type conn() :: DBConnection.conn()

  @type snowflake_conn_option() ::
          {:dsn, String.t()}
          | {:driver, String.t()}
          | {:server, String.t()}
          | {:warehouse, String.t()}
          | {:role, String.t()}
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

  @doc """
  Starts the connection process and connects to Snowflake.

  ## Options

  ### Snowflake Connection Options

  See: https://docs.snowflake.com/en/user-guide/odbc-parameters.html#required-connection-parameters

  * `:connection`

    * `:dsn` - Specifies the name of your DSN

    * `:driver` - Snowflake ODBC driver path

    * `:server` - Specifies the hostname for your account

    * `:uid` - Specifies the login name of the Snowflake user to authenticate

    * `:pwd` - A password is required to connect to Snowflake

    * `:database` - Specifies the default database to use for sessions initiated by the driver

    * `:schema` - Specifies the default schema to use for sessions initiated by the driver (default: `public`)

    * `:warehouse` - Specifies the default warehouse to use for sessions initiated by the driver

    * `:role` - Specifies the default role to use for sessions initiated by the driver

    * `:authenticator` - Specifies the authenticator to use for verifying user login credentials

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

  Start connection using the default configuration (UNIX domain socket):

      iex> {:ok, pid} = Snowpack.start_link(connection: [server: "account-id.snowflakecomputing.com", uid: "USER", pwd: "PASS"])
      {:ok, #PID<0.69.0>}

  Run a query after connection has been established:

      iex> {:ok, pid} = Snowpack.start_link(after_connect: &Snowpack.query!(&1, "SET time_zone = '+00:00'"))
      {:ok, #PID<0.69.0>}

  """
  @spec start_link([start_option()]) :: {:ok, pid()} | {:error, Snowpack.Error.t()}
  def start_link(options) do
    options = Keyword.put_new(options, :idle_interval, @default_session_keepalive)

    DBConnection.start_link(Snowpack.Protocol, options)
  end

  defmacrop is_iodata(data) do
    quote do
      is_list(unquote(data)) or is_binary(unquote(data))
    end
  end

  @doc """
  Runs a query.

  ## Examples

      iex> Snowpack.query(conn, "SELECT * FROM posts")
      {:ok, %Snowpack.Result{}}

  """
  @spec query(conn, iodata, list, [option()]) ::
          {:ok, Snowpack.Result.t()} | {:error, Exception.t()}
  def query(conn, statement, params \\ [], options \\ []) when is_iodata(statement) do
    # credo:disable-for-lines:2 Credo.Check.Readability.SinglePipe
    prepare_execute(conn, "", statement, params, options)
    |> query_result()
    |> IO.inspect(label: "Snowpack Query Result")
  end

  @doc """
  Runs a query.

  Returns `%Snowpack.Result{}` on success, or raises an exception if there was an error.

  See `query/4`.
  """
  @spec query!(conn, iodata, list, [option()]) :: Snowpack.Result.t()
  def query!(conn, statement, params \\ [], opts \\ []) do
    case query(conn, statement, params, opts) do
      {:ok, result} -> result
      {:error, exception} -> raise exception
    end
  end

  @doc """
  Prepares a query to be later executed.

  To execute the query, call `execute/4`. To close the query, call `close/3`.
  If a name is given, the name must be unique per query, as the name is cached
  but the statement isn't. If a new statement is given to an old name, the old
  statement will be the one effectively used.

  ## Options

  Options are passed to `DBConnection.prepare/3`, see it's documentation for
  all available options.

  ## Examples

      iex> {:ok, query} = Snowpack.prepare(conn, "", "SELECT ? * ?")
      iex> {:ok, %Snowpack.Result{rows: [row]}} = Snowpack.execute(conn, query, [2, 3])
      iex> row
      [6]

  """
  @spec prepare(conn(), iodata(), iodata(), [option()]) ::
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
  @spec prepare!(conn(), iodata(), iodata(), [option()]) :: Snowpack.Query.t()
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
    IO.inspect(query, label: "Snowpack Query")
    DBConnection.prepare_execute(conn, query, params, opts)
  end

  @doc """
  Prepares and executes a query in a single step.

  Returns `{%Snowpack.Query{}, %Snowpack.Result{}}` on success, or raises an exception if there was
  an error.

  See: `prepare_execute/5`.
  """
  @spec prepare_execute!(conn, iodata, iodata, list, [option()]) ::
          {Snowpack.Query.t(), Snowpack.Result.t()}
  def prepare_execute!(conn, name, statement, params \\ [], opts \\ [])
      when is_iodata(name) and is_iodata(statement) do
    query = %Snowpack.Query{name: name, statement: statement}
    IO.inspect(query, label: "Snowpack Query")
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
  @spec execute(conn(), Snowpack.Query.t(), list(), [option()]) ::
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
  @spec close(conn(), Snowpack.Query.t(), [option()]) :: :ok
  def close(conn, %Snowpack.Query{} = query, opts \\ []) do
    case DBConnection.close(conn, query, opts) do
      {:ok, _} ->
        :ok

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Returns a supervisor child specification for a DBConnection pool.
  """
  @spec child_spec([start_option()]) :: :supervisor.child_spec()
  def child_spec(opts) do
    # ensure_deps_started!(opts)
    DBConnection.child_spec(Snowpack.Protocol, opts)
  end

  defp query_result({:ok, _query, result}), do: {:ok, result}
  defp query_result({:error, _} = error), do: error
end
