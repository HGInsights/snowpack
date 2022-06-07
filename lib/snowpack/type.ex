defmodule Snowpack.Type do
  @moduledoc """
  Type conversions.

  Note the :odbc return types for decoding can be found here:
  http://erlang.org/doc/apps/odbc/databases.html#data-types-
  """

  require Logger

  @typedoc "Input param."
  @type param ::
          bitstring()
          | number()
          | date()
          | time()
          | datetime()
          | Decimal.t()

  @typedoc "Output value."
  @type return_value ::
          bitstring()
          | integer()
          | date()
          | datetime()
          | Decimal.t()

  @typedoc "Date as `{year, month, day}`"
  @type date :: {1..9_999, 1..12, 1..31}

  @typedoc "Time as `{hour, minute, sec, usec}`"
  @type time :: {0..24, 0..60, 0..60, 0..999_999}

  @typedoc "Datetime"
  @type datetime :: {date(), time()}

  @type value :: :null | term()

  @doc """
  Transforms input params into `:odbc` params.
  """
  @spec encode(value :: param(), opts :: Keyword.t()) :: {atom(), [nil | term()]}
  def encode(value, _) when is_boolean(value) do
    {:sql_bit, [value]}
  end

  def encode({_year, _month, _day} = date, _) do
    encoded =
      date
      |> Date.from_erl!()
      |> Date.to_iso8601()

    {{:sql_varchar, String.length(encoded)}, [encoded]}
  end

  def encode({hour, minute, sec, usec}, _) do
    precision = if usec == 0, do: 0, else: 6

    # credo:disable-for-lines:3 Credo.Check.Readability.SinglePipe
    encoded =
      Time.from_erl!({hour, minute, sec}, {usec, precision})
      |> Time.to_iso8601()

    {{:sql_varchar, String.length(encoded)}, [encoded]}
  end

  def encode({{year, month, day}, {hour, minute, sec}}, opts),
    do: encode({{year, month, day}, {hour, minute, sec, 0}}, opts)

  def encode({{year, month, day}, {hour, minute, sec, usec}}, _) do
    precision = if usec == 0, do: 0, else: 6

    # credo:disable-for-lines:6 Credo.Check.Readability.SinglePipe
    encoded =
      NaiveDateTime.from_erl!(
        {{year, month, day}, {hour, minute, sec}},
        {usec, precision}
      )
      |> NaiveDateTime.to_iso8601()

    {{:sql_varchar, String.length(encoded)}, [encoded]}
  end

  def encode(%NaiveDateTime{} = datetime, _) do
    encoded = NaiveDateTime.to_iso8601(datetime)
    {{:sql_varchar, String.length(encoded)}, [encoded]}
  end

  def encode(%DateTime{} = datetime, _) do
    encoded = DateTime.to_iso8601(datetime)
    {{:sql_varchar, String.length(encoded)}, [encoded]}
  end

  def encode(%Date{} = date, _) do
    encoded = Date.to_iso8601(date)
    {{:sql_varchar, String.length(encoded)}, [encoded]}
  end

  def encode(%Time{} = time, _) do
    encoded = Time.to_iso8601(time)
    {{:sql_varchar, String.length(encoded)}, [encoded]}
  end

  def encode(value, _)
      when is_integer(value) and value > -1_000_000_000 and
             value < 1_000_000_000 do
    {:sql_integer, [value]}
  end

  def encode(value, _) when is_integer(value) do
    encoded = to_string(value)
    {{:sql_varchar, String.length(encoded)}, [encoded]}
  end

  def encode(value, _) when is_float(value) do
    encoded = to_string(value)
    {{:sql_varchar, String.length(encoded)}, [encoded]}
  end

  def encode(%Decimal{} = value, _) do
    encoded = Decimal.to_string(value, :normal)

    precision = Decimal.Context.get().precision
    scale = calculate_decimal_scale(value)

    {{:sql_decimal, precision, scale}, [encoded]}
  end

  def encode(value, _) when is_binary(value) do
    {{:sql_varchar, byte_size(value)}, [value]}
  end

  def encode(nil, _), do: {:sql_integer, [:null]}

  def encode(value, _) do
    raise %Snowpack.Error{
      message: "could not parse param #{inspect(value)} of unrecognised type."
    }
  end

  @doc """
  Transforms `:odbc` return values to Elixir representations.
  """
  @spec decode(value(), opts :: Keyword.t()) :: return_value()
  def decode(:null, _), do: nil

  def decode(value, _) when is_boolean(value), do: value
  def decode(value, _) when is_integer(value), do: value
  def decode(value, _) when is_float(value), do: value

  def decode({{_year, _month, _day}, {_hour, _minute, _sec}} = value, _) do
    case NaiveDateTime.from_erl(value) do
      {:ok, datetime} -> datetime
      {:error, _error} -> value
    end
  end

  def decode(value, _) when is_binary(value) do
    parse_funcs = [&parse_to_int/1, &DateTimeParser.parse/1]

    Enum.find_value(parse_funcs, value, fn func ->
      case Kernel.apply(func, [value]) do
        {integer, ""} -> integer
        {:ok, result} -> result
        _ -> false
      end
    end)
  end

  def decode(value, _opts), do: value

  defp calculate_decimal_scale(dec) do
    coef_size = dec.coef |> Integer.digits() |> Enum.count()
    coef_size + dec.exp - 1
  end

  defp parse_to_int(value) when is_binary(value) do
    if String.starts_with?(value, "0") && String.length(value) > 1 do
      :error
    else
      Integer.parse(value)
    end
  end
end
