defmodule Plcholder.Jobs.Cleaner do
  alias Plcholder.Operation

  def clean do
    :ets.foldl(
      fn {waiting_for, _waiters}, _ ->
        case Operation.get_by_cid(waiting_for) do
          nil ->
            IO.puts "Could not find operation #{waiting_for}"

          %{operation: op} ->
            IO.puts("Cleaning #{waiting_for}")
            Plcholder.Jobs.notify_waiters(
              waiting_for,
              Plcholder.Verify.get_genesis_pkeys(op),
              false
            )
            :ets.delete(Plcholder.Jobs, waiting_for)
        end

      end,
      [],
      Plcholder.Jobs
    )
  end
end
