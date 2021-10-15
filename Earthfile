all:
  BUILD +static-code-analysis
  BUILD +test

static-code-analysis:
  FROM +setup-deps

  COPY --dir lib test ./
  COPY .formatter.exs .
  COPY .credo.exs .
  COPY README.md .
  COPY dialyzer.ignore-warnings .

  RUN mkdir -p priv/plts
  # RUN mix dialyzer --plt
  RUN mix format --check-formatted
  RUN mix deps.unlock --check-unused
  RUN mix credo --strict
  # RUN mix dialyzer --no-check

  SAVE ARTIFACT _build /_build
  SAVE ARTIFACT priv/plts /priv/plts

all-test:
  BUILD --build-arg ELIXIR=1.12.3 --build-arg OTP=24.1.2 --build-arg UBUNTU=focal-20210325 +test
  BUILD --build-arg ELIXIR=1.11.4 --build-arg OTP=23.3.2 --build-arg UBUNTU=focal-20210325 +test
  BUILD --build-arg ELIXIR=1.11.3 --build-arg OTP=23.2.5 --build-arg UBUNTU=focal-20210119 +test

quick-test:
  BUILD --build-arg ELIXIR=1.11.4 --build-arg OTP=23.3.2 --build-arg UBUNTU=focal-20210325 +test

test:
  FROM +setup-deps

  COPY --dir lib test ./
  COPY README.md .
  COPY .env.test .

  ENV SNOWPACK_DRIVER=/usr/lib/snowflake/odbc/lib/libSnowflake.so
  ENV SNOWPACK_PRIV_KEY_FILE=/tmp/rsa_key.p8

  # Run unit tests
  RUN --secret SNOWPACK_SERVER=+secrets/SNOWPACK_SERVER \
    --mount=type=secret,target=${SNOWPACK_PRIV_KEY_FILE},id=+secrets/SNOWPACK_PRIV_KEY \
    mix test --exclude ciskip:true

  SAVE ARTIFACT _build /_build

setup-base:
  ARG ELIXIR
  ARG OTP
  ARG UBUNTU
  FROM hexpm/elixir:$ELIXIR-erlang-$OTP-ubuntu-$UBUNTU

  RUN apt-get update && apt-get install -y \
    curl

  ARG SNOWFLAKE_VERSION=2.23.1

  RUN curl --output snowflake-odbc-${SNOWFLAKE_VERSION}.x86_64.deb \
        https://sfc-repo.snowflakecomputing.com/odbc/linux/${SNOWFLAKE_VERSION}/snowflake-odbc-${SNOWFLAKE_VERSION}.x86_64.deb \
     && dpkg -i snowflake-odbc-${SNOWFLAKE_VERSION}.x86_64.deb || true

  RUN apt-get update && yes N | apt-get -fy --no-install-recommends install && rm -r /var/lib/apt/lists/* /var/cache/*

  ENV ELIXIR_ASSERT_TIMEOUT=10000
  WORKDIR /src

setup-deps:
  FROM +setup-base

  COPY mix.exs .
  COPY mix.lock .

  RUN mix local.rebar --force
  RUN mix local.hex --force
  RUN mix deps.get
  RUN MIX_ENV=test mix deps.compile

  SAVE ARTIFACT deps /deps
  SAVE ARTIFACT _build /_build
