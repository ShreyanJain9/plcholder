defmodule Plcholder.Scraper do

  use Task

  def start_link(_) do
    Task.start_link(__MODULE__, :run, [0])
  end

  def run(date_after) do
    ops =
      HTTPoison.get!("https://plc.directory/export?after=#{date_after}").body
      |> String.split("\n")
      |> Enum.map(&Jason.decode!/1)

    for op <- ops do
      Plcholder.Verifier.start_link(op)
    end

    unless length(ops) < 1000 do
      ops
      |> List.last()
      |> Map.get("createdAt")
      |> run()
    end
  end

end
