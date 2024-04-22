defmodule :"Elixir.Plcholder.Repo.Migrations.Unique cids" do
  use Ecto.Migration

  def change do
    create index(:operations, [:cid], unique: true)
  end
end
