searchNodes=[{"doc":"Snowflake driver for Elixir.Documentation: http://hexdocs.pm/snowpackFeaturesAutomatic decoding and encoding of Elixir values to and from Snowflake's ODBC driver formatsSupports transactions, prepared queries, streaming, pooling and more via DBConnectionSupports Snowflake ODBC Drivers 2.22.5UsageAdd :snowpack to your dependencies:def deps() do [ {:snowpack, &quot;~&gt; 0.1.0&quot;} ] endMake sure you are using the latest version!opts = [ connection: [ role: &quot;DEV&quot;, warehouse: System.get_env(&quot;SNOWFLAKE_WH&quot;), uid: System.get_env(&quot;SNOWFLAKE_UID&quot;), pwd: System.get_env(&quot;SNOWFLAKE_PWD&quot;) ] ] {:ok, pid} = Snowpack.start_link(opts) Snowpack.query!(pid, &quot;select current_user()&quot;) Snowpack.query(pid, &quot;SELECT * FROM data&quot;) {:ok, %Snowpack.Result{ columns: [&quot;id&quot;, &quot;title&quot;], num_rows: 3, rows: [[1, &quot;Data 1&quot;], [2, &quot;Data 2&quot;], [3, &quot;Data 3&quot;]] }}It's recommended to start Snowpack under a supervision tree:defmodule MyApp.Application do use Application def start(_type, _args) do children = [ {Snowpack, uid: &quot;snowflake-uid&quot;, name: :snowpack} ] opts = [strategy: :one_for_one, name: MyApp.Supervisor] Supervisor.start_link(children, opts) end endand then we can refer to it by its :name:Snowpack.query!(:snowpack, &quot;SELECT NOW()&quot;).rows [[~N[2018-12-28 13:42:31]]]Data representationSnowflake ODBC Elixir ----- ------ NULL nil bool true | false int 42 float 42.0 decimal 42.0 date ~D[2013-10-12] time ~T[00:37:14] datetime ~N[2013-10-12 00:37:14] # (2) timestamp ~U[2013-10-12 00:37:14Z] # (2) char &quot;é&quot; text &quot;snowpack&quot; binary &lt;&lt;1, 2, 3&gt;&gt; bit &lt;&lt;1::size(1), 0::size(1)&gt;&gt; array [1, 2, 3] object %{key: &quot;value&quot;}Notes:See DecimalDatetime fields are represented as NaiveDateTime, however a UTC DateTime can be used for encoding as well","ref":"Snowpack.html","title":"Snowpack","type":"module"},{"doc":"Returns a supervisor child specification for a DBConnection pool.","ref":"Snowpack.html#child_spec/1","title":"Snowpack.child_spec/1","type":"function"},{"doc":"Closes a prepared query.Returns :ok on success, or raises an exception if there was an error.OptionsOptions are passed to DBConnection.close/3, see it's documentation for all available options.","ref":"Snowpack.html#close/3","title":"Snowpack.close/3","type":"function"},{"doc":"Executes a prepared query.OptionsOptions are passed to DBConnection.execute/4, see it's documentation for all available options.Examplesiex&gt; {:ok, query} = Snowpack.prepare(conn, &quot;&quot;, &quot;SELECT ? * ?&quot;) iex&gt; {:ok, %Snowpack.Result{rows: [row]}} = Snowpack.execute(conn, query, [2, 3]) iex&gt; row [6]","ref":"Snowpack.html#execute/4","title":"Snowpack.execute/4","type":"function"},{"doc":"Executes a prepared query.Returns %Snowpack.Result{} on success, or raises an exception if there was an error.See: execute/4.","ref":"Snowpack.html#execute!/4","title":"Snowpack.execute!/4","type":"function"},{"doc":"Prepares a query to be later executed.To execute the query, call execute/4. To close the query, call close/3. If a name is given, the name must be unique per query, as the name is cached but the statement isn't. If a new statement is given to an old name, the old statement will be the one effectively used.OptionsOptions are passed to DBConnection.prepare/3, see it's documentation for all available options.Examplesiex&gt; {:ok, query} = Snowpack.prepare(conn, &quot;&quot;, &quot;SELECT ? * ?&quot;) iex&gt; {:ok, %Snowpack.Result{rows: [row]}} = Snowpack.execute(conn, query, [2, 3]) iex&gt; row [6]","ref":"Snowpack.html#prepare/4","title":"Snowpack.prepare/4","type":"function"},{"doc":"Prepares a query.Returns %Snowpack.Query{} on success, or raises an exception if there was an error.See prepare/4.","ref":"Snowpack.html#prepare!/4","title":"Snowpack.prepare!/4","type":"function"},{"doc":"Prepares and executes a query in a single step.Multiple resultsIf a query returns multiple results (e.g. it's calling a procedure that returns multiple results) an error is raised. If a query may return multiple results it's recommended to use stream/4 instead.OptionsOptions are passed to DBConnection.prepare_execute/4, see it's documentation for all available options.Examplesiex&gt; {:ok, _query, %Snowpack.Result{rows: [row]}} = Snowpack.prepare_execute(conn, &quot;&quot;, &quot;SELECT ? * ?&quot;, [2, 3]) iex&gt; row [6]","ref":"Snowpack.html#prepare_execute/5","title":"Snowpack.prepare_execute/5","type":"function"},{"doc":"Prepares and executes a query in a single step.Returns {%Snowpack.Query{}, %Snowpack.Result{}} on success, or raises an exception if there was an error.See: prepare_execute/5.","ref":"Snowpack.html#prepare_execute!/5","title":"Snowpack.prepare_execute!/5","type":"function"},{"doc":"Runs a query.Examplesiex&gt; Snowpack.query(conn, &quot;SELECT * FROM posts&quot;) {:ok, %Snowpack.Result{}}","ref":"Snowpack.html#query/4","title":"Snowpack.query/4","type":"function"},{"doc":"Runs a query.Returns %Snowpack.Result{} on success, or raises an exception if there was an error.See query/4.","ref":"Snowpack.html#query!/4","title":"Snowpack.query!/4","type":"function"},{"doc":"Starts the connection process and connects to Snowflake.OptionsSnowflake Connection OptionsSee: https://docs.snowflake.com/en/user-guide/odbc-parameters.html#required-connection-parameters:connection:dsn - Specifies the name of your DSN:driver - Snowflake ODBC driver path:server - Specifies the hostname for your account:uid - Specifies the login name of the Snowflake user to authenticate:pwd - A password is required to connect to Snowflake:database - Specifies the default database to use for sessions initiated by the driver:schema - Specifies the default schema to use for sessions initiated by the driver (default: public):warehouse - Specifies the default warehouse to use for sessions initiated by the driver:role - Specifies the default role to use for sessions initiated by the driver:authenticator - Specifies the authenticator to use for verifying user login credentials:priv_key_file - Specifies the local path to the private key fileDBConnection OptionsThe given options are passed down to DBConnection, some of the most commonly used ones are documented below::after_connect - A function to run after the connection has been established, either a 1-arity fun, a {module, function, args} tuple, or nil (default: nil):pool - The pool module to use, defaults to built-in pool provided by DBconnection:pool_size - The size of the poolSee DBConnection.start_link/2 for more information and a full list of available options.ExamplesStart connection using the default configuration (UNIX domain socket):iex&gt; {:ok, pid} = Snowpack.start_link(connection: [server: &quot;account-id.snowflakecomputing.com&quot;, uid: &quot;USER&quot;, pwd: &quot;PASS&quot;]) {:ok, #PID&lt;0.69.0&gt;}Run a query after connection has been established:iex&gt; {:ok, pid} = Snowpack.start_link(after_connect: &amp;Snowpack.query!(&amp;1, &quot;SET time_zone = &#39;+00:00&#39;&quot;)) {:ok, #PID&lt;0.69.0&gt;}","ref":"Snowpack.html#start_link/1","title":"Snowpack.start_link/1","type":"function"},{"doc":"","ref":"Snowpack.html#t:conn/0","title":"Snowpack.conn/0","type":"type"},{"doc":"","ref":"Snowpack.html#t:option/0","title":"Snowpack.option/0","type":"type"},{"doc":"","ref":"Snowpack.html#t:snowflake_conn_option/0","title":"Snowpack.snowflake_conn_option/0","type":"type"},{"doc":"","ref":"Snowpack.html#t:start_option/0","title":"Snowpack.start_option/0","type":"type"},{"doc":"Adapter to Erlang's :odbc module.This module is a GenServer that handles communication between Elixir and Erlang's :odbc module.It is used by Snowpack.Protocol and should not generally be accessed directly.","ref":"Snowpack.ODBC.html","title":"Snowpack.ODBC","type":"module"},{"doc":"Returns a specification to start this module under a supervisor.See Supervisor.","ref":"Snowpack.ODBC.html#child_spec/1","title":"Snowpack.ODBC.child_spec/1","type":"function"},{"doc":"Describes the given table.","ref":"Snowpack.ODBC.html#describe/2","title":"Snowpack.ODBC.describe/2","type":"function"},{"doc":"","ref":"Snowpack.ODBC.html#describe_result/2","title":"Snowpack.ODBC.describe_result/2","type":"function"},{"doc":"Disconnects from the ODBC driver.pid is the :odbc process id","ref":"Snowpack.ODBC.html#disconnect/1","title":"Snowpack.ODBC.disconnect/1","type":"function"},{"doc":"Callback implementation for GenServer.init/1.","ref":"Snowpack.ODBC.html#init/1","title":"Snowpack.ODBC.init/1","type":"function"},{"doc":"Sends a parametrized query to the ODBC driver.Interface to :odbc.param_query/3.See Erlang's ODBC guide for usage details and examples.pid is the :odbc process id statement is the SQL query string params are the parameters to send with the SQL query opts are options to be passed on to :odbc with_query_id runs query in transaction and selects LAST_QUERY_ID()","ref":"Snowpack.ODBC.html#query/5","title":"Snowpack.ODBC.query/5","type":"function"},{"doc":"Starts the connection process to the ODBC driver.conn_str should be a connection string in the format required by your ODBC driver. opts will be passed verbatim to :odbc.connect/2.","ref":"Snowpack.ODBC.html#start_link/2","title":"Snowpack.ODBC.start_link/2","type":"function"},{"doc":"Implementation of DBConnection behaviour for Snowpack.ODBC.Handles translation of concepts to what ODBC expects and holds state for a connection.This module is not called directly, but rather through other Snowpack modules or DBConnection functions.","ref":"Snowpack.Protocol.html","title":"Snowpack.Protocol","type":"module"},{"doc":"Callback implementation for DBConnection.checkin/1.","ref":"Snowpack.Protocol.html#checkin/1","title":"Snowpack.Protocol.checkin/1","type":"function"},{"doc":"Callback implementation for DBConnection.checkout/1.","ref":"Snowpack.Protocol.html#checkout/1","title":"Snowpack.Protocol.checkout/1","type":"function"},{"doc":"Callback implementation for DBConnection.connect/1.","ref":"Snowpack.Protocol.html#connect/1","title":"Snowpack.Protocol.connect/1","type":"function"},{"doc":"Callback implementation for DBConnection.disconnect/2.","ref":"Snowpack.Protocol.html#disconnect/2","title":"Snowpack.Protocol.disconnect/2","type":"function"},{"doc":"Callback implementation for DBConnection.handle_begin/2.","ref":"Snowpack.Protocol.html#handle_begin/2","title":"Snowpack.Protocol.handle_begin/2","type":"function"},{"doc":"Callback implementation for DBConnection.handle_close/3.","ref":"Snowpack.Protocol.html#handle_close/3","title":"Snowpack.Protocol.handle_close/3","type":"function"},{"doc":"Callback implementation for DBConnection.handle_commit/2.","ref":"Snowpack.Protocol.html#handle_commit/2","title":"Snowpack.Protocol.handle_commit/2","type":"function"},{"doc":"Callback implementation for DBConnection.handle_deallocate/4.","ref":"Snowpack.Protocol.html#handle_deallocate/4","title":"Snowpack.Protocol.handle_deallocate/4","type":"function"},{"doc":"Callback implementation for DBConnection.handle_declare/4.","ref":"Snowpack.Protocol.html#handle_declare/4","title":"Snowpack.Protocol.handle_declare/4","type":"function"},{"doc":"Callback implementation for DBConnection.handle_execute/4.","ref":"Snowpack.Protocol.html#handle_execute/4","title":"Snowpack.Protocol.handle_execute/4","type":"function"},{"doc":"Callback implementation for DBConnection.handle_fetch/4.","ref":"Snowpack.Protocol.html#handle_fetch/4","title":"Snowpack.Protocol.handle_fetch/4","type":"function"},{"doc":"","ref":"Snowpack.Protocol.html#handle_first/4","title":"Snowpack.Protocol.handle_first/4","type":"function"},{"doc":"","ref":"Snowpack.Protocol.html#handle_next/4","title":"Snowpack.Protocol.handle_next/4","type":"function"},{"doc":"Callback implementation for DBConnection.handle_prepare/3.","ref":"Snowpack.Protocol.html#handle_prepare/3","title":"Snowpack.Protocol.handle_prepare/3","type":"function"},{"doc":"Callback implementation for DBConnection.handle_rollback/2.","ref":"Snowpack.Protocol.html#handle_rollback/2","title":"Snowpack.Protocol.handle_rollback/2","type":"function"},{"doc":"Callback implementation for DBConnection.handle_status/2.","ref":"Snowpack.Protocol.html#handle_status/2","title":"Snowpack.Protocol.handle_status/2","type":"function"},{"doc":"Callback implementation for DBConnection.ping/1.","ref":"Snowpack.Protocol.html#ping/1","title":"Snowpack.Protocol.ping/1","type":"function"},{"doc":"","ref":"Snowpack.Protocol.html#reconnect/2","title":"Snowpack.Protocol.reconnect/2","type":"function"},{"doc":"","ref":"Snowpack.Protocol.html#t:opts/0","title":"Snowpack.Protocol.opts/0","type":"type"},{"doc":"","ref":"Snowpack.Protocol.html#t:params/0","title":"Snowpack.Protocol.params/0","type":"type"},{"doc":"","ref":"Snowpack.Protocol.html#t:query/0","title":"Snowpack.Protocol.query/0","type":"type"},{"doc":"","ref":"Snowpack.Protocol.html#t:result/0","title":"Snowpack.Protocol.result/0","type":"type"},{"doc":"Process state.Includes::pid: the pid of the ODBC process:snowflake: the transaction state. Can be :idle (not in a transaction).:conn_opts: the options used to set up the connection.","ref":"Snowpack.Protocol.html#t:state/0","title":"Snowpack.Protocol.state/0","type":"type"},{"doc":"","ref":"Snowpack.Protocol.html#t:status/0","title":"Snowpack.Protocol.status/0","type":"type"},{"doc":"Implementation of DBConnection.Query for Snowpack.The structure is:name - currently not used.statement - SQL statement to run using :odbc.","ref":"Snowpack.Query.html","title":"Snowpack.Query","type":"module"},{"doc":"","ref":"Snowpack.Query.html#t:t/0","title":"Snowpack.Query.t/0","type":"type"},{"doc":"Result struct returned from any successful query.Its public fields are::columns - The column names;:num_rows - The number of fetched or affected rows;:rows - The result set. A list of tuples, each inner tuple corresponding to a row, each element in the inner tuple corresponds to a column;WarningsDepending on SQL MODE, a given query may error or just return warnings. If result.num_warnings is non-zero it means there were warnings and they can be retrieved by making another query:Snowpack.query!(conn, &quot;SHOW WARNINGS&quot;)","ref":"Snowpack.Result.html","title":"Snowpack.Result","type":"module"},{"doc":"","ref":"Snowpack.Result.html#t:t/0","title":"Snowpack.Result.t/0","type":"type"},{"doc":"Type conversions.Note the :odbc return types for decoding can be found here: http://erlang.org/doc/apps/odbc/databases.html#data-types-","ref":"Snowpack.Type.html","title":"Snowpack.Type","type":"module"},{"doc":"Transforms :odbc return values to Elixir representations.","ref":"Snowpack.Type.html#decode/2","title":"Snowpack.Type.decode/2","type":"function"},{"doc":"Transforms input params into :odbc params.","ref":"Snowpack.Type.html#encode/2","title":"Snowpack.Type.encode/2","type":"function"},{"doc":"Date as {year, month, day}","ref":"Snowpack.Type.html#t:date/0","title":"Snowpack.Type.date/0","type":"type"},{"doc":"Datetime","ref":"Snowpack.Type.html#t:datetime/0","title":"Snowpack.Type.datetime/0","type":"type"},{"doc":"Input param.","ref":"Snowpack.Type.html#t:param/0","title":"Snowpack.Type.param/0","type":"type"},{"doc":"Output value.","ref":"Snowpack.Type.html#t:return_value/0","title":"Snowpack.Type.return_value/0","type":"type"},{"doc":"Time as {hour, minute, sec, usec}","ref":"Snowpack.Type.html#t:time/0","title":"Snowpack.Type.time/0","type":"type"},{"doc":"Cache of fetching and storing the table column types.","ref":"Snowpack.TypeCache.html","title":"Snowpack.TypeCache","type":"module"},{"doc":"","ref":"Snowpack.TypeCache.html#fetch_column_types/3","title":"Snowpack.TypeCache.fetch_column_types/3","type":"function"},{"doc":"","ref":"Snowpack.TypeCache.html#get_column_types/1","title":"Snowpack.TypeCache.get_column_types/1","type":"function"},{"doc":"","ref":"Snowpack.TypeCache.html#key_from_statement/1","title":"Snowpack.TypeCache.key_from_statement/1","type":"function"},{"doc":"","ref":"Snowpack.TypeCache.html#start_link/0","title":"Snowpack.TypeCache.start_link/0","type":"function"},{"doc":"Parser for table column data types.","ref":"Snowpack.TypeParser.html","title":"Snowpack.TypeParser","type":"module"},{"doc":"","ref":"Snowpack.TypeParser.html#parse_rows/3","title":"Snowpack.TypeParser.parse_rows/3","type":"function"},{"doc":"Defines an error returned from the ODBC adapter.message is the full message returned by ODBCodbc_code is an atom representing the returned SQLSTATE or the string representation of the code if it cannot be translated.","ref":"Snowpack.Error.html","title":"Snowpack.Error","type":"exception"},{"doc":"","ref":"Snowpack.Error.html#t:t/0","title":"Snowpack.Error.t/0","type":"type"},{"doc":"0.3.0 (2021-08-20)FeaturesHandle results from a non select statement (#12) (a5b6f11), closes #120.2.0 (2021-05-11)FeaturesUpdate type parsing to cover more types and be based on query result (fixes #5) (8cf6b85), closes #5","ref":"changelog.html","title":"0.3.0 (2021-08-20)","type":"extras"},{"doc":"Bug Fixesset the default idle_interval to 5 min (#9) (67edb80), closes #9Choresci: refactor ci and Earthfile to configure elixir, erlang, ubuntu, and snowflake versions via args (#7) (3e39531), closes #7","ref":"changelog.html#0-1-4-2021-04-30","title":"0.3.0 (2021-08-20) - 0.1.4 (2021-04-30)","type":"extras"},{"doc":"Bug Fixesprovide a default idle_interval of 3600 sec to be used as a session keepalive (#6) (4a54529), closes #6","ref":"changelog.html#0-1-3-2021-04-16","title":"0.3.0 (2021-08-20) - 0.1.3 (2021-04-16)","type":"extras"},{"doc":"Bug Fixesstarted adding more tests for queries (#3) (d3f4c3d), closes #3","ref":"changelog.html#0-1-2-2021-04-13","title":"0.3.0 (2021-08-20) - 0.1.2 (2021-04-13)","type":"extras"},{"doc":"Bug Fixesparse zero-precision NUMBER types from Snowflake as integers, rather than decimals (#4) (85d1665), closes #4Choresci: fix next-version output var name (9c8140c)0.1.0 (2021-03-17)Featuresrelease 0.1.0 and docs cleanup (6048141)","ref":"changelog.html#0-1-1-2021-03-25","title":"0.3.0 (2021-08-20) - 0.1.1 (2021-03-25)","type":"extras"},{"doc":"Bug Fixesuse UTF-8 binary encoding and handle unknown column types (#2) (3c3c55b), closes #2Choresfix CHANGELOG version (b94b857)0.0.1 (2021-03-11)Choresgithub actions, credo, ex_docs, semantic release (1f12897)new app (f352e61)Featuresimplement basic DBConnection query behavior (#1) (5f164e9), closes #1Initial commit (9e5a9ba)","ref":"changelog.html#0-0-2-2021-03-17","title":"0.3.0 (2021-08-20) - 0.0.2 (2021-03-17)","type":"extras"}]