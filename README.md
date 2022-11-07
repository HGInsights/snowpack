# Snowpack

[![CI](https://github.com/HGInsights/snowpack/actions/workflows/elixir-ci.yml/badge.svg)](https://github.com/HGInsights/snowpack/actions/workflows/elixir-ci.yml)
[![hex.pm version](https://img.shields.io/hexpm/v/snowpack.svg)](https://hex.pm/packages/snowpack)
[![hex.pm license](https://img.shields.io/hexpm/l/snowpack.svg)](https://github.com/HGInsights/snowpack/blob/main/LICENSE)
[![Last Updated](https://img.shields.io/github/last-commit/HGInsights/snowpack.svg)](https://github.com/HGInsights/snowpack/commits/main)


<!-- MDOC !-->

Snowflake driver for Elixir.

## ⚠️ Important ⚠️ - Not in active development

This project is no longer under active development. Please consider these alternatives:
- [Avalanche](https://github.com/HGInsights/avalanche): uses Snowflake's V2 REST API (For projects that do not need the ODBC driver)
- [Snowflex](https://github.com/pepsico-ecommerce/snowflex): uses the ODBC driver (like Snowpack)

## Features

- Automatic decoding and encoding of Elixir values to and from Snowflake's ODBC driver formats
- Supports transactions, prepared queries, pooling and more via [DBConnection](https://github.com/elixir-ecto/db_connection)
- Supports Snowflake ODBC Drivers 2.24.7+

## Usage

Add `:snowpack` to your dependencies:

```elixir
def deps() do
  [
    {:snowpack, "~> 0.6.0"}
  ]
end
```

Make sure you are using the latest version!

```elixir
opts = [
  connection: [
    role: "DEV",
    warehouse: System.get_env("SNOWFLAKE_WH"),
    uid: System.get_env("SNOWFLAKE_UID"),
    pwd: System.get_env("SNOWFLAKE_PWD")
  ]
]

{:ok, pid} = Snowpack.start_link(opts)
Snowpack.query!(pid, "select current_user()")

Snowpack.query(pid, "SELECT * FROM data")
{:ok,
 %Snowpack.Result{
   columns: ["id", "title"],
   num_rows: 3,
   rows: [[1, "Data 1"], [2, "Data 2"], [3, "Data 3"]]
 }}
```

It's recommended to start Snowpack under a supervision tree:

```elixir
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      {Snowpack, uid: "snowflake-uid", name: :snowpack}
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

and then we can refer to it by its `:name`:

```elixir
Snowpack.query!(:snowpack, "SELECT NOW()").rows
[[~N[2018-12-28 13:42:31]]]
```

## Data representation

```
Snowflake ODBC       Elixir
-----                ------
NULL                 nil
bool                 true | false
int                  42
float                42.0
decimal              42.0 # (1)
date                 ~D[2013-10-12]
time                 ~T[00:37:14]
datetime             ~N[2013-10-12 00:37:14]  # (2)
timestamp            ~U[2013-10-12 00:37:14Z] # (2)
char                 "é"
text                 "snowpack"
binary               <<1, 2, 3>>
bit                  <<1::size(1), 0::size(1)>>
array                [1, 2, 3]
object               %{key: "value"}
```

Notes:

1. See [Decimal](https://github.com/ericmj/decimal)

2. Datetime fields are represented as `NaiveDateTime`, however a UTC `DateTime` can be used for encoding as well.

<!-- MDOC !-->

## Documentation

Documentation is automatically published to
[hexdocs.pm](https://hexdocs.pm/snowpack) on release. You may build the
documentation locally with

```
MIX_ENV=docs mix docs
```

## Erlang ODBC on Apple M1

Install Dependencies via Homebrew

```
brew install asdf openssl@1.1 libiodbc wxwidgets
```

NOTE: you may need to unlink `unixodbc` to install and use `libiodbc`, or replace `libiodbc` with `unixodbc` below.

Configure your shell for [asdf](https://asdf-vm.com/).

Install asdf plugins.

```
asdf plugin add erlang
asdf plugin add elixir
```

Configure the KERL compiler used by asdf.

```
export CFLAGS="-O2 -g -fno-stack-check"
export KERL_CONFIGURE_OPTIONS="--with-ssl=$(brew --prefix openssl@1.1)/ --with-wx-config=$(brew --prefix wxwidgets)/bin/wx-config --with-odbc=$(brew --prefix libiodbc)"
export CPPFLAGS="-I$(brew --prefix libiodbc)/include"
export LDFLAGS="-L$(brew --prefix libiodbc)/lib"
```

Install Erlang and Elixir

```
asdf install erlang 25.0.3
asdf install elixir 1.13.4-otp-25
```

## Running tests locally

Copy over the contents from `.env.test` to `.env.test.local`:
```bash
cp .env.test .env.test.local
```

Generate an `rsa_key` for your Snowflake instance and replace the following env
vars in `.env.test.local` (they have `replace_me` default values). It will look
something like this:
```
SNOWPACK_DRIVER=/path/to/driver/libSnowflake.dylib
SNOWPACK_SERVER=something_like_this.snowflakecomputing.com
SNOWPACK_PRIV_KEY_FILE=/path/for/the/rsa_key.p8>
```

Notes:
- `/opt/snowflake/snowflakeodbc/lib/libSnowflake.dylib` is the default on Macs.
- You can learn more about them
  [here](https://docs.snowflake.com/en/user-guide/key-pair-auth.html)
- There is no need to load this to your `env` since we are using `Vapor` to
  handle config.

## Contributing

Issues and PRs are welcome! See our organization [CONTRIBUTING.md](https://github.com/HGInsights/.github/blob/main/CONTRIBUTING.md) for more information about best-practices and passing CI.
