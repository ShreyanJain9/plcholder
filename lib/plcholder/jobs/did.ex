defmodule Plcholder.Jobs.Did do
  use GenServer

  def start_link(did) do
    GenServer.start_link(__MODULE__, did, name: via_tuple(did))
  end

  def init(did) do
    {:ok, {did, %{}}, {:continue, did}}
  end

  def via_tuple(did) do
    {:via, Registry, {Plcholder.Jobs.Registry, did}}
  end

  def handle_continue(did, {did, %{}}) do
    {:noreply,
     {did,
      did
      |> Plcholder.Operation.get_by_did()
      |> Enum.map(&{&1.cid, &1})
      |> Map.new()}}
  end

  def handle_cast(
        {:handle_op, %{"cid" => cid, "operation" => %{"prev" => prev} = operation} = op_meta},
        {did, ops_map}
      ) do
    verified? =
      case prev do
        nil ->
          Plcholder.Verify.verify_genesis(operation, did)

        _ ->
          rkeys =
            ops_map[prev |> IO.inspect()].operation
            |> Plcholder.Verify.get_genesis_pkeys()

          Plcholder.Verify.verify_op_signature(operation, rkeys)
      end
      {:ok, op} = save_to_db(op_meta, verified?)

    {:noreply, {did, Map.put(ops_map, cid, op)}}
  end

  def handle_cast(:quit, _) do
    {:stop, :normal, nil}
  end

  def quit_all do
    Plcholder.Jobs.get_all()
    |> Enum.each(fn {_, pid, _, _} -> GenServer.cast(pid, :quit) end)

    Plcholder.Jobs.Supervisor
    |> Process.whereis
    |> Process.exit(:kill)
  end

  def save_to_db(operation, op_checks_out?) do
    Plcholder.Repo.insert(
      %Plcholder.Operation{
        cid: operation["cid"],
        operation: operation["operation"],
        did: operation["did"],
        created_at: DateTime.from_iso8601(operation["createdAt"]) |> elem(1) |> DateTime.truncate(:second),
        prev: operation["operation"]["prev"],
        sig: operation["operation"]["sig"],
        verified?: op_checks_out?
      })
  end

  def get(did) do
    case Plcholder.Jobs.Registry.get(did) do
      nil ->
        {:ok, pid} = DynamicSupervisor.start_child(Plcholder.Jobs.Supervisor, {Plcholder.Jobs.Did, did})
        pid

      pid -> pid
    end
  end

  def handle_op(%{"did" => did} = operation) do
    get(did) |> GenServer.cast({:handle_op, operation})
  end
end
