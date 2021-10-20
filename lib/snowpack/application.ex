defmodule Snowpack.Application do
  @moduledoc false
  use Application

  @spec start(any, any) :: {:error, any} | {:ok, pid}
  def start(_, _) do
    children = [
      Snowpack.TypeCache
    ]

    opts = [strategy: :one_for_one, name: Snowpack.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
