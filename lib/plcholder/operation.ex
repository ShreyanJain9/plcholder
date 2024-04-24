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
    |> unique_constraint(:cid, name: :operations_cid_unique?)
  end

  def get_op_rotkeys(cid, my_cid) do
    op = get_by_cid(cid)
    case op && op.operation do
      %{"type" => "plc_operation", "rotationKeys" => keys} -> keys
      %{"type" => "create", "recoveryKey" => key} -> [key]
      nil ->
        case Plcholder.Jobs.wait_for(cid, my_cid) do
          nil -> []
          {_, ^cid, keys} -> keys
        end
    end
  end

  def get_by_cid(cid) do
    case cid do
      nil -> nil
      cid -> Plcholder.Repo.get_by(Plcholder.Operation, cid: cid)
    end
  end
end
