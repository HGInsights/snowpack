Code.put_compiler_option(:warnings_as_errors, true)
Vapor.load!([%Vapor.Provider.Dotenv{}])

Application.ensure_all_started(:mimic)

Mimic.copy(Snowpack.Protocol)
Mimic.copy(Snowpack.TypeCache)
Mimic.copy(Snowpack.ODBC)
Mimic.copy(:odbc)

ExUnit.start(exclude: [skip: true])

defmodule Snowpack.TestHelper do
  defmacro query(stat, params, opts \\ []) do
    quote do
      case Snowpack.query(var!(context)[:pid], unquote(stat), unquote(params), unquote(opts)) do
        {:ok, %Snowpack.Result{rows: nil}} -> :ok
        {:ok, %Snowpack.Result{rows: rows}} -> rows
        {:error, err} -> err
      end
    end
  end

  @spec odbc_ini_opts :: keyword()
  def odbc_ini_opts do
    [
      connection: [
        dsn: System.fetch_env!("SNOWPACK_DSN_NAME")
      ],
      pool_size: 1
      # queue_target: 50,
      # queue_interval: 1000
    ]
  end

  @spec okta_opts :: keyword()
  def okta_opts do
    [
      connection: [
        driver: System.fetch_env!("SNOWPACK_DRIVER"),
        server: System.fetch_env!("SNOWPACK_SERVER"),
        uid: System.fetch_env!("SNOWPACK_OKTA_UID"),
        pwd: System.fetch_env!("SNOWPACK_OKTA_PWD"),
        authenticator: System.fetch_env!("SNOWPACK_OKTA_AUTHENTICATOR")
      ],
      pool_size: 1
    ]
  end

  @spec key_pair_opts :: keyword()
  def key_pair_opts do
    [
      connection: [
        driver: System.fetch_env!("SNOWPACK_DRIVER"),
        server: System.fetch_env!("SNOWPACK_SERVER"),
        role: System.fetch_env!("SNOWPACK_KEYPAIR_ROLE"),
        warehouse: System.fetch_env!("SNOWPACK_KEYPAIR_WAREHOUSE"),
        database: System.fetch_env!("SNOWPACK_KEYPAIR_DATABASE"),
        schema: System.fetch_env!("SNOWPACK_KEYPAIR_SCHEMA"),
        uid: System.fetch_env!("SNOWPACK_KEYPAIR_UID"),
        authenticator: System.fetch_env!("SNOWPACK_KEYPAIR_AUTHENTICATOR"),
        priv_key_file: System.fetch_env!("SNOWPACK_PRIV_KEY_FILE")
      ],
      pool_size: 1
    ]
  end
end
