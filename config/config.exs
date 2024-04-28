import Config

config :plcholder, Plcholder.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "plcholder",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  migration_lock: nil,
  pool_size: 20,
  queue_target: 10000


config :plcholder, ecto_repos: [Plcholder.Repo]

config :logger,
  backends: [:console, {LoggerFileBackend, :error_log}],
  format: "[$level] $message\n",
  level: :info

config :logger, :error_log,
  path: "tmp/info.log",
  level: :debug
