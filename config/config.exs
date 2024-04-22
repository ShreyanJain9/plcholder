import Config

config :plcholder, Plcholder.Repo,
  adapter: Ecto.Adapters.Sqlite3,
  database: "plcholder_repo.db"

config :plcholder, ecto_repos: [Plcholder.Repo]
