defmodule Plcholder.Jobs do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    {:ok, :ets.new(__MODULE__, [:set, :public, :named_table])}
  end

  def register(cid) do
    :ets.insert(__MODULE__, {cid,
     self(
       # PID of the job running for that CID
     ),
     [
       # List of waiting processes
     ]})
  end

  def get(cid) do
    :ets.lookup(__MODULE__, cid)
    |> List.first()
  end

  def verified(cid) do
    self = self()
    {^cid, ^self, waiters} =
      :ets.lookup(__MODULE__, cid)
      |> List.first()
    :ets.insert(__MODULE__, {cid, :verified, waiters})
  end

  def failed_to_verify(cid) do
    self = self()
    {^cid, ^self, waiters} =
      :ets.lookup(__MODULE__, cid)
      |> List.first()
    :ets.insert(__MODULE__, {cid, :verify_failed, waiters})
  end

  def waiters(cid) do
    :ets.lookup(__MODULE__, cid)
    |> List.first()
    |> elem(2)
  end

  def wait_for(cid) do
    self = self()
    unless ( job = get(cid) ) == nil do
      :ets.insert(__MODULE__, {cid, elem(job, 1), [self | elem(job, 2)]})
    else
      Process.sleep(10)
      wait_for(cid)
    end
    receive do
      {:verified, ^cid, rot_keys} -> rot_keys
      {:verify_failed, ^cid, rot_keys} ->
        IO.puts("failed to verify #{cid}")
        rot_keys
      _ -> IO.puts("unknown message received for #{cid} at #{self}"); wait_for(cid)
    end
  end

end
