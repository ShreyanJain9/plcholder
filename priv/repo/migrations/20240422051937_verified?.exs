defmodule :"Elixir.Plcholder.Repo.Migrations.Verified?" do
  use Ecto.Migration

  def change do
    alter table(:operations) do
      add :verified?, :boolean
    end
  end
end
