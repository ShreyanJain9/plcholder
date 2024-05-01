defmodule Plcholder.Jobs.Supervisor do
  use DynamicSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one, restart: :transient)
  end

  def start_for_op(op) do
    DynamicSupervisor.start_child(__MODULE__, {Plcholder.Verifier, op})
  end
end
