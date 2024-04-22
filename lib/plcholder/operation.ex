defmodule Plcholder.Operation do

  use Ecto.Schema
  import Ecto.Changeset

  schema "operations" do
    field :cid, :string
    field :operation, :map
    field :did, :string
    field :created_at, :utc_datetime
    field :prev, :string
    field :sig, :string
    field :verified?, :boolean
    timestamps()
  end

  @doc false
  def changeset(operation, attrs) do
    operation
    |> cast(attrs, [:cid, :operation, :did])
    |> validate_required([:cid, :operation, :did])
  end

  import Ecto.Query

  def get_op_rotkeys(cid) do
    case get(cid).operation do
      %{"type" => "plc_operation", "rotationKeys" => keys} -> keys
      %{"type" => "create", "recoveryKey" => key} -> [key]
      nil ->
        case Plcholder.Jobs.wait_for(cid) do
          nil -> []
          {_, ^cid, keys} -> keys
        end
    end
  end

  def get(cid) do

    query = from o in Plcholder.Operation,
      where: o.cid == ^cid,
      select: o
    query |> Plcholder.Repo.one()
  end

end
