defmodule Snowpack.TelemetryTest do
  use ExUnit.Case, async: false

  use Mimic

  import Snowpack.TestHelper

  describe "telemetry" do
    setup do
      Mimic.set_mimic_global()

      {:ok, pid} = start_supervised({Snowpack, key_pair_opts()})

      {:ok, [pid: pid]}
    end

    test "reports query spans", context do
      {test_name, _arity} = __ENV__.function

      parent = self()
      ref = make_ref()

      handler = fn event, measurements, meta, _config ->
        case event do
          [:snowpack, :query, :start] ->
            assert is_integer(measurements.system_time)
            assert is_binary(meta.query)
            assert is_list(meta.params)
            send(parent, {ref, :start})

          [:snowpack, :query, :stop] ->
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
          [:snowpack, :query, :start],
          [:snowpack, :query, :stop]
        ],
        handler,
        nil
      )

      _rows = query("SELECT ?;", [3])

      assert_receive {^ref, :start}, 1_000
      assert_receive {^ref, :stop}, 1_000

      :telemetry.detach(to_string(test_name))
    end

    test "reports query spans with errors", context do
      {test_name, _arity} = __ENV__.function

      parent = self()
      ref = make_ref()

      handler = fn event, measurements, meta, _config ->
        case event do
          [:snowpack, :query, :start] ->
            assert is_integer(measurements.system_time)
            assert is_binary(meta.query)
            assert is_list(meta.params)
            send(parent, {ref, :start})

          [:snowpack, :query, :stop] ->
            assert is_integer(measurements.duration)
            assert is_binary(meta.query)
            assert is_list(meta.params)
            assert %Snowpack.Error{} = meta.error
            send(parent, {ref, :stop})

          _ ->
            flunk("Unknown event")
        end
      end

      :telemetry.attach_many(
        to_string(test_name),
        [
          [:snowpack, :query, :start],
          [:snowpack, :query, :stop]
        ],
        handler,
        nil
      )

      expect(Snowpack.ODBC, :query, fn _pid, _statement, _params, _opts, _with_query_id ->
        {:error, %Snowpack.Error{message: "SQL compilation error"}}
      end)

      _rows = query("SELECT * FROM BAD_TABLE LIMIT ?;", [3])

      assert_receive {^ref, :start}, 1_000
      assert_receive {^ref, :stop}, 1_000

      :telemetry.detach(to_string(test_name))
    end

    @tag :capture_log
    test "reports query exceptions", context do
      {test_name, _arity} = __ENV__.function

      parent = self()
      ref = make_ref()

      handler = fn event, measurements, meta, _config ->
        case event do
          [:snowpack, :query, :exception] ->
            assert is_integer(measurements.duration)
            assert meta.query == "SELECT 13;"
            assert is_list(meta.params)
            assert :error = meta.kind
            assert %RuntimeError{} = meta.error
            assert is_list(meta.stacktrace)
            send(parent, {ref, :exception})

          _ ->
            flunk("Unknown event")
        end
      end

      :telemetry.attach_many(
        to_string(test_name),
        [
          [:snowpack, :query, :exception]
        ],
        handler,
        nil
      )

      expect(Snowpack.ODBC, :query, fn _pid, _statement, _params, _opts, _with_query_id ->
        raise("failed!")
      end)

      expect Snowpack.ODBC, :query, fn _pid, _statement, _params, _opts, _with_query_id ->
        {:selected, ["13"], [{13}]}
      end

      assert [[13]] = query("SELECT 13;", [])

      assert_receive {^ref, :exception}, 1_000

      :telemetry.detach(to_string(test_name))
    end

    test "reports query exceptions with default metadata" do
      {test_name, _arity} = __ENV__.function

      parent = self()
      ref = make_ref()

      start_time = System.monotonic_time()

      handler = fn event, measurements, meta, _config ->
        case event do
          [:snowpack, :query, :exception] ->
            assert is_integer(measurements.duration)
            assert is_atom(meta.kind)
            assert %RuntimeError{} = meta.error
            assert is_list(meta.stacktrace)
            send(parent, {ref, :exception})

          _ ->
            flunk("Unknown event")
        end
      end

      :telemetry.attach_many(
        to_string(test_name),
        [
          [:snowpack, :query, :exception]
        ],
        handler,
        nil
      )

      stacktrace = []
      error = RuntimeError.exception("test")

      Snowpack.Telemetry.exception(:query, start_time, :exit, error, stacktrace)

      assert_receive {^ref, :exception}, 1_000

      :telemetry.detach(to_string(test_name))
    end

    test "reports generic events" do
      {test_name, _arity} = __ENV__.function

      parent = self()
      ref = make_ref()

      handler = fn event, measurements, meta, _config ->
        case event do
          [:snowpack, :custom_event] ->
            assert is_integer(measurements.test)
            assert is_atom(meta.test)
            send(parent, {ref, :custom_event})

          _ ->
            flunk("Unknown event")
        end
      end

      :telemetry.attach_many(
        to_string(test_name),
        [
          [:snowpack, :custom_event]
        ],
        handler,
        nil
      )

      Snowpack.Telemetry.event(:custom_event, %{test: 123}, %{test: :test})

      assert_receive {^ref, :custom_event}, 1_000

      :telemetry.detach(to_string(test_name))
    end
  end
end
