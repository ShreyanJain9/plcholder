defmodule Plcholder.Verifier do

  use Task

  def start_link(op) do
    Task.start_link(__MODULE__, :run, [op])
  end

  def run(operation) do
    cid = operation["cid"]
    op = operation["operation"]

    Plcholder.Jobs.Registry.register(cid)

    op_checks_out? =
      unless op["prev"] do
        # Op is a genesis
        Plcholder.Verify.verify_genesis(op, operation["did"])
      else
        rotkeys = Plcholder.Operation.get_op_rotkeys(op["prev"])
        Plcholder.Verify.verify_op_signature(op, rotkeys)
      end

    save_to_db(operation, op_checks_out?)

    Plcholder.Jobs.notify_waiters(cid, Plcholder.Verify.get_genesis_pkeys(op), op_checks_out?)
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
end
