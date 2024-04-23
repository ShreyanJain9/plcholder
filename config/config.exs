import Config

config :plcholder, Plcholder.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "plcholder",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"

config :plcholder, ecto_repos: [Plcholder.Repo]
