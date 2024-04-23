defmodule Plcholder.Repo do

  use Ecto.Repo,
    otp_app: :plcholder,
    adapter: Ecto.Adapters.Postgres

end
