defmodule Snowpack.Telemetry do
  @moduledoc """
  Telemetry integration.

  Unless specified, all time's are in `:native` units.

  Snowpack executes the following events:

  * `[:snowpack, :query, :start]` - Executed at the start of each query sent to Snowflake.

  #### Measurements

    * `:system_time` - The time the query started

  #### Metadata:

    * `:query` - The query sent to the database as a string
    * `:params` - The query parameters

  * `[:snowpack, :query, :stop]` - Executed at the end of each query sent to Snowflake.

  #### Measurements

    * `:end_time` - The time the query ended
    * `:duration` - The time spent executing the query (end_time - start_time)

  #### Metadata:

    * `:query` - The query sent to the database as a string
    * `:params` - The query parameters
    * `:result` - The query result (selected, updated)
    * `:num_rows` - The number of rows effected by the query
    * `:error` - Present if any error occurred while processing the query. (optional)

  * `[:snowpack, :query, :exception]` - Executed if executing a query throws an exception.

  #### Measurements

    * `:end_time` - The time the query ended
    * `:duration` - The time spent executing the query (end_time - start_time)

  #### Metadata

    * `:kind` - The type of exception.
    * `:error` - Error description or error data.
    * `:stacktrace` - The stacktrace

  """

  @doc false
  @spec start(atom, map, map) :: integer
  # Emits a `start` telemetry event and returns the the start time
  def start(event, meta \\ %{}, extra_measurements \\ %{}) do
    start_time = System.monotonic_time()

    :telemetry.execute(
      [:snowpack, event, :start],
      Map.merge(extra_measurements, %{system_time: System.system_time()}),
      meta
    )

    start_time
  end

  @doc false
  @spec stop(atom, number, map, map) :: :ok
  # Emits a stop event.
  def stop(event, start_time, meta \\ %{}, extra_measurements \\ %{}) do
    end_time = System.monotonic_time()

    measurements =
      Map.merge(extra_measurements, %{end_time: end_time, duration: end_time - start_time})

    :telemetry.execute(
      [:snowpack, event, :stop],
      measurements,
      meta
    )
  end

  @doc false
  @spec exception(atom, number, any, any, any, map, map) :: :ok
  def exception(
        event,
        start_time,
        kind,
        reason,
        stack,
        meta \\ %{},
        extra_measurements \\ %{}
      ) do
    end_time = System.monotonic_time()

    measurements =
      Map.merge(extra_measurements, %{end_time: end_time, duration: end_time - start_time})

    meta =
      meta
      |> Map.put(:kind, kind)
      |> Map.put(:error, reason)
      |> Map.put(:stacktrace, stack)

    :telemetry.execute([:snowpack, event, :exception], measurements, meta)
  end

  @doc false
  @spec event(atom, number | map, map) :: :ok
  # Used for reporting generic events
  def event(event, measurements, meta) do
    :telemetry.execute([:snowpack, event], measurements, meta)
  end
end
