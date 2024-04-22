defmodule Plcholder.Scraper do

  use Task
  import Ecto.Query

  def start_link(_) do
    Task.start_link(__MODULE__, :run, [get_last_date() || "0"])
  end

  def get_last_date() do
    Plcholder.Operation
    |> order_by(desc: :created_at)
    |> limit(1)
    |> select([:created_at])
    |> Plcholder.Repo.one()
    |> Map.get(:created_at)
  end

  def run(date_after) do
    ops =
      HTTPoison.get!("https://plc.directory/export?after=#{DateTime.to_iso8601(date_after)}").body
      |> String.split("\n")
      |> Enum.map(&Jason.decode!/1)

    for op <- ops do
      Plcholder.Verifier.start_link(op)
    end

    unless length(ops) < 1000 do
      ops
      |> List.last()
      |> Map.get("createdAt")
      |> DateTime.from_iso8601()
      |> elem(1)
      |> run()
    end
  end

end
