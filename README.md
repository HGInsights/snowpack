# Snowpack

[![CI](https://github.com/HGInsights/snowpack/workflows/CI/badge.svg)](https://github.com/HGInsights/snowpack/actions/workflows/elixir.yml)

<!-- MDOC !-->

Snowflake driver for Elixir.

Documentation: <http://hexdocs.pm/snowpack>

## Features

- Automatic decoding and encoding of Elixir values to and from Snowflake's ODBC driver formats
- Supports transactions, prepared queries, streaming, pooling and more via
  [DBConnection](https://github.com/elixir-ecto/db_connection)
- Supports Snowflake ODBC Drivers 2.22.5

## Usage

Add `:snowpack` to your dependencies:

```elixir
def deps() do
  [
    {:snowpack, "~> 0.1.0"}
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
bool                 1 | 0
int                  42
float                42.0
decimal              #Decimal<42.0> # (1)
date                 ~D[2013-10-12]
time                 ~T[00:37:14]
datetime             ~N[2013-10-12 00:37:14]  # (2)
timestamp            ~U[2013-10-12 00:37:14Z] # (2)
char                 "é"
text                 "snowpack"
binary               <<1, 2, 3>>
bit                  <<1::size(1), 0::size(1)>>
```

Notes:

1. See [Decimal](https://github.com/ericmj/decimal)

2. Datetime fields are represented as `NaiveDateTime`, however a UTC `DateTime` can be used for encoding as well

<!-- MDOC !-->

## Contributing

Run tests:

```
git clone git@github.com:HGInsights/snowpack.git
cd snowpack
mix deps.get
mix test
```

Working with [Earthly](https://earthly.dev/) for CI

```
brew install earthly

earthly +static-code-analysis

earthly --secret SNOWPACK_SERVER="my-account.snowflakecomputing.com" --secret-file SNOWPACK_PRIV_KEY=./rsa_key.p8 +test
```

## License

The source code is under Apache License 2.0.

Copyright (c) 2021 HG Insights

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the
License. You may obtain a copy of the License at
[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an
"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific
language governing permissions and limitations under the License.
