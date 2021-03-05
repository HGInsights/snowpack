defmodule Snowpack do
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  @doc """
  Hello world.

  ## Examples

      iex> Snowpack.hello()
      :world

  """
  @spec hello :: atom()
  def hello do
    :world
  end
end
