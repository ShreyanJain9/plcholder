defmodule Plcholder.Scraper do

  use Task
  import Ecto.Query

  def start_link(_) do
    Task.start_link(__MODULE__, :run, [get_last_date()])
  end

  def get_last_date() do
    Plcholder.Operation
    |> order_by(desc: :created_at)
    |> limit(1)
    |> select([:created_at])
    |> Plcholder.Repo.one()
    |> case do
      nil -> ~U[1970-01-01 00:00:00Z]
      %{created_at: created_at} -> created_at
    end
  end

  def run(date_after, times_scraped \\ 0) do
    ops =
      HTTPoison.get!("https://plc.directory/export?after=#{DateTime.to_iso8601(date_after)}").body
      |> String.split("\n")
      |> Enum.map(&Jason.decode!/1)

    for op <- ops do
      Task.Supervisor.start_child(Plcholder.TaskSupervisor, Plcholder.Verifier.run_fn(op))
    end

    unless length(ops) < 1000 do
      ops
      |> List.last()
      |> Map.get("createdAt")
      |> DateTime.from_iso8601()
      |> elem(1)
      |> run(handle_times_scraped(times_scraped))
    else
      IO.puts("No more ops left!!")
    end
  end

  def handle_times_scraped(n) when n > 500, do: Process.sleep(300000); 0
  def handle_times_scraped(n), do: n + 1

end
