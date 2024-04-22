defmodule Plcholder.Verifier do
  use Task

  def start_link(operation) do
    Task.start_link(__MODULE__, :run, [operation])
  end

  def run(operation) do
    cid = operation["cid"]
    op = operation["operation"]

    Plcholder.Jobs.register(cid)

    op_checks_out? =
      unless op["prev"] do
        # Op is a genesis
        Plcholder.Verify.verify_genesis(op, operation["did"])
      else
        rotkeys = Plcholder.Operation.get_op_rotkeys(op["prev"])
        Plcholder.Verify.verify_op_signatures(op, rotkeys)
      end

    apply(
      Plcholder.Jobs,
      verify_status = case op_checks_out? do
        true -> :verified
        false -> :failed_to_verify
      end,
      [cid]
    )
    save_to_db(operation, op_checks_out?)
    for waiter <- Plcholder.Jobs.waiters(cid) do
      send(
        waiter,
        {verify_status, cid, Plcholder.Operation.get_op_rotkeys(op["cid"])}
      )
    end
  end

  def save_to_db(operation, op_checks_out?) do
    Plcholder.Repo.insert(
      %Plcholder.Operation{
        cid: operation["cid"],
        operation: operation["operation"],
        did: operation["did"],
        created_at: operation["created_at"],
        prev: operation["operation"]["prev"],
        sig: operation["operation"]["sig"],
        verified?: op_checks_out?
      })
  end
end
