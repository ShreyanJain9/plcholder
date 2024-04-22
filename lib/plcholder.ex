defmodule Plcholder do
end

defmodule Plcholder.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    children = [
      {Plcholder.Multicodec, "multicodec.csv"},
    ]
    opts = [strategy: :one_for_one, name: Plcholder.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
