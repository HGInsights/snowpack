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
  # RUN mix dialyzer --plt
  RUN mix format --check-formatted
  RUN mix deps.unlock --check-unused
  # RUN mix credo --strict
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

  RUN ls -la /opt/snowflake_odbc/lib

  # Run unit tests
  RUN --secret SNOWPACK_SERVER=+secrets/SNOWPACK_SERVER \
    # --secret SNOWPACK_PRIV_KEY_FILE=+secrets/SNOWPACK_PRIV_KEY_FILE \
    mix test

  SAVE ARTIFACT _build /_build

setup-base:
  ARG ELIXIR=1.11.3
  ARG OTP=23.2.7
  FROM hexpm/elixir-amd64:$ELIXIR-erlang-$OTP-alpine-3.13.2

  RUN apk add --no-progress --no-cache --update \
    git build-base bash unixodbc unixodbc-dev perl grep libc6-compat

  RUN ln -s /lib/libc.musl-x86_64.so.1 /lib/ld-linux-x86-64.so.2

  ARG SNOWFLAKE_VERSION=2.22.5

  RUN wget https://sfc-repo.snowflakecomputing.com/odbc/linux/${SNOWFLAKE_VERSION}/snowflake_linux_x8664_odbc-${SNOWFLAKE_VERSION}.tgz -P /tmp \
    && tar -xvf /tmp/snowflake_linux_x8664_odbc-${SNOWFLAKE_VERSION}.tgz -C /opt/

  RUN /opt/snowflake_odbc/unixodbc_setup.sh

  # RUN ls /opt/snowflake_odbc/lib

  # RUN ldd /opt/snowflake_odbc/lib/libSnowflake.so

  RUN perl -i -pe 's|/usr/lib64/libodbcinst.so|/usr/lib/libodbcinst.so.2|;' /opt/snowflake_odbc/lib/simba.snowflake.ini

  # RUN cat /opt/snowflake_odbc/lib/simba.snowflake.ini

  RUN echo -e '\n\
  [Snowpack]\n\
  Description=SnowflakeDB\n\
  Driver=SnowflakeDSIIDriver\n\
  Locale=en-US\n\
  PORT=443\n\
  SSL=on'\
  >> /etc/odbc.ini

  # RUN cat /etc/odbc.ini
  # RUN cat /etc/odbcinst.ini
  # RUN ls /usr/lib

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
