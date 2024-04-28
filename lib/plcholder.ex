defmodule Plcholder do
end

defmodule Plcholder.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    children = [
      {Plcholder.Multicodec, "multicodec.csv"},
      Plcholder.Repo,
      Plcholder.Jobs,
      Plcholder.Jobs.Supervisor,
      Plcholder.Jobs.Registry
    ] ++ case System.get_env("PLCHOLDER_SCRAPE_NOW") do
      "true" -> [Plcholder.Scraper]
      _ -> []
    end
    opts = [strategy: :one_for_one, name: Plcholder.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
