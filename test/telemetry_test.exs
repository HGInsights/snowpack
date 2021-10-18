defmodule TelemetryTest do
  use ExUnit.Case, async: false

  import Snowpack.TestHelper

  describe "telemetry" do
    setup do
      {:ok, pid} = Snowpack.start_link(key_pair_opts())

      {:ok, [pid: pid]}
    end

    test "reports query spans", context do
      {test_name, _arity} = __ENV__.function

      parent = self()
      ref = make_ref()
      prefix = event_prefix()

      handler = fn event, measurements, meta, _config ->
        case event do
          [^prefix, :snowpack, :query, :start] ->
            assert is_integer(measurements.system_time)
            assert is_binary(meta.query)
            assert is_list(meta.params)
            send(parent, {ref, :start})

          [^prefix, :snowpack, :query, :stop] ->
            assert is_integer(measurements.end_time)
            assert is_integer(measurements.duration)
            assert is_binary(meta.query)
            assert is_list(meta.params)
            assert is_integer(meta.num_rows)
            send(parent, {ref, :stop})

          _ ->
            flunk("Unknown event")
        end
      end

      :telemetry.attach_many(
        to_string(test_name),
        [
          [prefix, :snowpack, :query, :start],
          [prefix, :snowpack, :query, :stop],
          [prefix, :snowpack, :query, :exception]
        ],
        handler,
        nil
      )

      _rows = query("SELECT * FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER LIMIT ?;", [3])

      assert_receive {^ref, :start}
      assert_receive {^ref, :stop}

      :telemetry.detach(to_string(test_name))
    end

    test "reports query spans with errors", context do
      {test_name, _arity} = __ENV__.function

      parent = self()
      ref = make_ref()
      prefix = event_prefix()

      handler = fn event, measurements, meta, _config ->
        case event do
          [^prefix, :snowpack, :query, :start] ->
            assert is_integer(measurements.system_time)
            assert is_binary(meta.query)
            assert is_list(meta.params)
            send(parent, {ref, :start})

          [^prefix, :snowpack, :query, :stop] ->
            assert is_integer(measurements.end_time)
            assert is_integer(measurements.duration)
            assert is_binary(meta.query)
            assert is_list(meta.params)
            assert is_struct(meta.error)
            send(parent, {ref, :stop})

          _ ->
            flunk("Unknown event")
        end
      end

      :telemetry.attach_many(
        to_string(test_name),
        [
          [prefix, :snowpack, :query, :start],
          [prefix, :snowpack, :query, :stop],
          [prefix, :snowpack, :query, :exception]
        ],
        handler,
        nil
      )

      _rows = query("SELECT * FROM SNOWFLAKE_SAMPLE_DATA.BAD_SCHEMA.CUSTOMER LIMIT ?;", [3])

      assert_receive {^ref, :start}
      assert_receive {^ref, :stop}

      :telemetry.detach(to_string(test_name))
    end
  end
end
