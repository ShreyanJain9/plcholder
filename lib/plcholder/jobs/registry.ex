defmodule Plcholder.Jobs.Registry do
  def start_link(_) do
    Registry.start_link(keys: :unique, name: __MODULE__)
  end

  def register(cid) do
    Registry.register(__MODULE__, cid, [])
  end

  def get(cid) do
    with [{pid, _}] <- Registry.lookup(__MODULE__, cid) do
      pid
    else
      _ -> nil
    end
  end

  def my_cid(pid \\ self()) do
    [cid] = Registry.keys(__MODULE__, pid)
    cid
  end

  def child_spec(_) do
    Supervisor.child_spec({Registry, [keys: :unique, name: __MODULE__]}, id: __MODULE__)
  end
end
