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

  @doc """
  Transforms input params into `:odbc` params.
  """
  @spec encode(value :: param(), opts :: Keyword.t()) ::
          {:odbc.odbc_data_type(), [:odbc.value()]}
  def encode(value, _) when is_boolean(value) do
    {:sql_bit, [value]}
  end

  def encode({_year, _month, _day} = date, _) do
    encoded =
      date
      |> Date.from_erl!()
      |> to_encoded_string()

    {{:sql_varchar, String.length(encoded)}, [encoded]}
  end

  def encode({hour, minute, sec, usec}, _) do
    precision = if usec == 0, do: 0, else: 6

    encoded =
      Time.from_erl!({hour, minute, sec}, {usec, precision})
      |> to_encoded_string()

    {{:sql_varchar, String.length(encoded)}, [encoded]}
  end

  def encode({{year, month, day}, {hour, minute, sec, usec}}, _) do
    precision = if usec == 0, do: 0, else: 6

    encoded =
      NaiveDateTime.from_erl!(
        {{year, month, day}, {hour, minute, sec}},
        {usec, precision}
      )
      |> to_encoded_string()

    {{:sql_varchar, String.length(encoded)}, [encoded]}
  end

  def encode(%NaiveDateTime{} = datetime, _) do
    encoded = to_encoded_string(datetime)
    {{:sql_varchar, String.length(encoded)}, [encoded]}
  end

  def encode(%DateTime{} = datetime, _) do
    encoded = to_encoded_string(datetime)
    {{:sql_varchar, String.length(encoded)}, [encoded]}
  end

  def encode(%Date{} = date, _) do
    encoded = to_encoded_string(date)
    {{:sql_varchar, String.length(encoded)}, [encoded]}
  end

  def encode(value, _)
      when is_integer(value) and value > -1_000_000_000 and
             value < 1_000_000_000 do
    {:sql_integer, [value]}
  end

  def encode(value, _) when is_integer(value) do
    encoded = to_encoded_string(value)
    {{:sql_varchar, String.length(encoded)}, [encoded]}
  end

  def encode(value, _) when is_float(value) do
    encoded = to_encoded_string(value)
    {{:sql_varchar, String.length(encoded)}, [encoded]}
  end

  def encode(%Decimal{} = value, _) do
    string = Decimal.to_string(value, :normal)
    encoded = to_encoded_string(string)

    precision = Decimal.Context.get().precision
    scale = calculate_decimal_scale(value)

    odbc_data_type = {:sql_decimal, precision, scale}
    {odbc_data_type, [encoded]}
  end

  def encode(value, _) when is_binary(value) do
    encoded = to_encoded_string(value)

    {{:sql_varchar, String.length(encoded)}, [encoded]}
  end

  def encode(nil, _) do
    {:sql_integer, [:null]}
  end

  def encode(values, v) when is_list(values),
    do: Enum.map(values, &encode(&1, v))

  def encode(value, _) do
    raise %Snowpack.Error{
      message: "could not parse param #{inspect(value)} of unrecognised type."
    }
  end

  @doc """
  Transforms `:odbc` return values to Elixir representations.
  """
  @spec decode(:odbc.value(), opts :: Keyword.t()) :: return_value()
  def decode(value, _) when is_float(value) do
    Decimal.from_float(value)
  end

  def decode(value, _opts) when is_binary(value) do
    to_string(value)
  end

  def decode(value, _) when is_list(value) do
    to_string(value)
  end

  def decode(:null, _) do
    nil
  end

  def decode({date, {h, m, s}}, opts) do
    decode({date, {h, m, s, 0}}, opts)
  end

  def decode({{year, month, day}, {hour, minute, second, msecond}}, _) do
    {:ok, date} = Date.new(year, month, day)
    {:ok, time} = Time.new(hour, minute, second, msecond)
    {:ok, datetime} = NaiveDateTime.new(date, time)
    datetime
  end

  def decode(value, _) do
    value
  end

  defp to_encoded_string(data) do
    data
    |> to_string()
  end

  defp calculate_decimal_scale(dec) do
    coef_size = dec.coef |> Integer.digits() |> Enum.count()
    coef_size + dec.exp - 1
  end
end
