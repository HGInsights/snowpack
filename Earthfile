all:
  BUILD +static-code-analysis
  BUILD +all-test

static-code-analysis:
  FROM +setup-deps

  COPY --dir lib test ./
  COPY .formatter.exs .
  COPY .credo.exs .
  COPY README.md .
  COPY dialyzer.ignore-warnings .

  RUN mkdir -p priv/plts
  RUN mix dialyzer --plt
  RUN mix format --check-formatted
  RUN mix deps.unlock --check-unused
  RUN mix credo --strict
  # RUN mix dialyzer --no-check

  SAVE ARTIFACT _build /_build
  SAVE ARTIFACT priv/plts /priv/plts

all-test:
  BUILD --build-arg ELIXIR=1.11.3 --build-arg OTP=21.3.8.18 +test
  BUILD --build-arg ELIXIR=1.11.3 --build-arg OTP=23.2.7 +test

test:
  FROM +setup-deps
  RUN MIX_ENV=test mix deps.compile
  COPY --dir lib test ./
  COPY README.md .
  COPY .env.test .
  COPY rsa_key.p8 /tmp/

  ENV SNOWPACK_DRIVER=/opt/snowflake_odbc/lib/libSnowflake.so
  ENV SNOWPACK_PRIV_KEY_FILE=/tmp/rsa_key.p8

  # Run unit tests
  RUN --secret SNOWPACK_SERVER=+secrets/SNOWPACK_SERVER \
    # --secret SNOWPACK_PRIV_KEY_FILE=+secrets/SNOWPACK_PRIV_KEY_FILE \
    mix test --exclude ciskip

  SAVE ARTIFACT _build /_build

setup-base:
  ARG ELIXIR=1.11.3
  ARG OTP=23.2.7
  FROM hexpm/elixir-amd64:$ELIXIR-erlang-$OTP-ubuntu-xenial-20201014

  RUN apt-get install -y \
    unixodbc \
    wget

  ARG SNOWFLAKE_VERSION=2.22.5

  RUN wget https://sfc-repo.snowflakecomputing.com/odbc/linux/${SNOWFLAKE_VERSION}/snowflake_linux_x8664_odbc-${SNOWFLAKE_VERSION}.tgz -P /tmp \
    && tar -xvf /tmp/snowflake_linux_x8664_odbc-${SNOWFLAKE_VERSION}.tgz -C /opt/

  RUN /opt/snowflake_odbc/unixodbc_setup.sh
  RUN perl -i -pe 's|/usr/lib64/libodbcinst.so|/usr/lib/x86_64-linux-gnu/libodbcinst.so.2|;' /opt/snowflake_odbc/lib/simba.snowflake.ini

  RUN echo -e '\n\
  [Snowpack]\n\
  Description=SnowflakeDB\n\
  Driver=SnowflakeDSIIDriver\n\
  Locale=en-US\n\
  PORT=443\n\
  SSL=on'\
  >> /etc/odbc.ini

  ENV ELIXIR_ASSERT_TIMEOUT=10000
  WORKDIR /src

setup-deps:
  FROM +setup-base

  COPY mix.exs .
  COPY mix.lock .

  RUN mix local.rebar --force
  RUN mix local.hex --force
  RUN mix deps.get
  RUN mix deps.compile

  SAVE ARTIFACT deps /deps
  SAVE ARTIFACT _build /_build
