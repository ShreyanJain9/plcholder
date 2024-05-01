defmodule Plcholder.Operation do

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

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
    |> validate_required([:cid, :operation, :did, :sig, :created_at, :verified?])
    |> unique_constraint(:cid, name: :operations_cid_unique?)
  end

  def get_op_rotkeys(cid) do
    op = get_by_cid(cid)
    case op && op.operation do
      %{"type" => "plc_operation", "rotationKeys" => keys} -> keys
      %{"type" => "create", "recoveryKey" => key} -> [key]
      nil ->
        Plcholder.Jobs.wait_for(cid)
    end
  end

  def get_by_cid(cid) do
    case cid do
      nil -> nil
      cid -> Plcholder.Repo.get_by(Plcholder.Operation, cid: cid)
    end
  end

  def get_by_did(did) do
    Plcholder.Operation
    |> where(did: ^did)
    |> order_by(asc: :created_at)
    |> Plcholder.Repo.all()
  end

end
