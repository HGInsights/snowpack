defmodule Snowpack.Result do
  @moduledoc """
  Result struct returned from any successful query.

  Its public fields are:

    * `:columns` - The column names;
    * `:num_rows` - The number of fetched or affected rows;
    * `:rows` - The result set. A list of tuples, each inner tuple corresponding to a
      row, each element in the inner tuple corresponds to a column;
  """

  defstruct [
    :columns,
    :num_rows,
    :rows
  ]

  @type t :: %__MODULE__{
          columns: [String.t()] | nil,
          num_rows: non_neg_integer() | nil,
          rows: [{term()}] | nil
        }
end
