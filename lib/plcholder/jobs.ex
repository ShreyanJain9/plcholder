defmodule Plcholder.Jobs do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    {:ok, :ets.new(__MODULE__, [:set, :public, :named_table])}
  end

  def add_waiter(waiting_for, waiter_cid) do
    case :ets.lookup(__MODULE__, waiting_for) do
      [{cid, list_of_waiters}] -> :ets.insert(__MODULE__, {cid, [waiter_cid | list_of_waiters]})
      [] -> :ets.insert(__MODULE__, {waiting_for, [waiter_cid]})
    end
  end

  def waiters_have_been_notified(cid) do
    :ets.delete(__MODULE__, cid)
  end

  def waiters(cid) do
    case :ets.lookup(__MODULE__, cid) do
      [{_cid, list_of_waiters}] ->
        list_of_waiters
        |> Enum.map(&Plcholder.Jobs.Registry.get/1)

      [] ->
        []
    end
  end

  def notify_waiters(cid, rotkeys, verify_status) do
    verify_status_atom =
      case verify_status do
        true -> :verified
        false -> :failed_to_verify
      end

    list_of_waiters = waiters(cid)

    Enum.each(list_of_waiters, fn pid ->
      send(pid, {verify_status_atom, cid, rotkeys})
    end)

    waiters_have_been_notified(cid)
  end

  def wait_for(cid) do
    my_cid = Plcholder.Jobs.Registry.my_cid()
    add_waiter(cid, my_cid)

    msg_wait(cid)
  end

  def msg_wait(cid) do
    receive do
      {:verified, ^cid, rotkeys} ->
        rotkeys

      {:failed_to_verify, ^cid, rotkeys} ->
        IO.puts("Failed to verify #{cid}. Rotkeys: #{inspect(rotkeys)}")

      unexpected_msg ->
        IO.puts("Unexpected message #{inspect(unexpected_msg)}")
        msg_wait(cid)
    end
  end
end
