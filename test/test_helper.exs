defmodule TestHelper do
  def opts() do
    [
      driver: System.fetch_env!("SNOWPACK_DRIVER"),
      server: System.fetch_env!("SNOWPACK_SERVER"),
      role: System.fetch_env!("SNOWPACK_ROLE"),
      warehouse: System.fetch_env!("SNOWPACK_WAREHOUSE"),
      uid: System.fetch_env!("SNOWPACK_UID"),
      pwd: System.fetch_env!("SNOWPACK_PWD"),
      authenticator: System.fetch_env!("SNOWPACK_AUTHENTICATOR")
    ]
  end
end

ExUnit.start()
Vapor.load!([%Vapor.Provider.Dotenv{}])
