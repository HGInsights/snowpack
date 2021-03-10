defmodule Snowpack.Result do
  @moduledoc """
  Result struct returned from any successful query.

  Its public fields are:

    * `:columns` - The column names;
    * `:num_rows` - The number of fetched or affected rows;
    * `:rows` - The result set. A list of tuples, each inner tuple corresponding to a
      row, each element in the inner tuple corresponds to a column;

  ## Warnings

  Depending on SQL MODE, a given query may error or just return warnings.
  If `result.num_warnings` is non-zero it means there were warnings and they can be
  retrieved by making another query:

      Snowpack.query!(conn, "SHOW WARNINGS")

  """

  @type t :: %__MODULE__{
          columns: [String.t()] | nil,
          num_rows: non_neg_integer() | nil,
          rows: [{term()}] | nil
        }

  defstruct [
    :columns,
    :num_rows,
    :rows
  ]
end
