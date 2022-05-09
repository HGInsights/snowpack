defmodule Snowpack.Error do
  @moduledoc """
  Defines an error returned from the ODBC adapter.

  * `message` is the full message returned by ODBC
  * `odbc_code` is an atom representing the returned
    [SQLSTATE](https://docs.microsoft.com/en-us/sql/odbc/reference/appendixes/appendix-a-odbc-error-codes)
    or the string representation of the code if it cannot be translated.
  * `native_code` is a string representing the returned Snowflake code.
  """

  defexception [:message, :odbc_code, :native_code]

  @type t :: %__MODULE__{
          :__exception__ => true,
          message: binary(),
          odbc_code: atom() | binary(),
          native_code: binary()
        }

  @spec exception(Keyword.t()) :: t()
  def exception({odbc_code, native_code, reason}) do
    %__MODULE__{
      message:
        to_string(reason) <>
          " | ODBC_CODE " <>
          to_string(odbc_code) <>
          " | SNOWFLAKE_CODE " <> to_string(native_code),
      odbc_code: translate_odbc_code(to_string(odbc_code)),
      native_code: to_string(native_code)
    }
  end

  @spec exception(binary()) :: t()
  def exception(message) do
    %__MODULE__{
      message: to_string(message)
    }
  end

  @spec message(t()) :: String.t()
  def message(%{message: message}), do: message

  defp translate_odbc_code("08" <> _), do: :connection_exception
  defp translate_odbc_code(code), do: code

  defimpl String.Chars do
    @spec to_string(Snowpack.Error.t()) :: binary
    def to_string(error) do
      Snowpack.Error.message(error)
    end
  end
end
