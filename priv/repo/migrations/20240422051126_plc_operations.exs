defmodule Plcholder.Repo.Migrations.PlcOperations do
  use Ecto.Migration

  def change do
    create table(:operations) do
      add :cid, :string
      add :operation, :map
      add :did, :string
      add :created_at, :utc_datetime
      add :prev, :string
      add :sig, :string
      timestamps()
    end
    create index(:operations, [:cid, :did, :prev])
  end
end
