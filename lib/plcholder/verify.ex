defmodule Plcholder.Verify do
  alias Plcholder.Multicodec
  alias Plcholder.DagCBOR
  alias Plcholder.K256

  def genesis_to_did(%{"prev" => nil} = signed_genesis) do
    "did:plc:" <>
      with {:ok, signed_genesis_json} <-
             signed_genesis
             |> Jason.encode(),
           {:ok, signed_genesis_cbor} <-
             signed_genesis_json
             |> Plcholder.DagCBOR.encode(),
           do:
             :crypto.hash(:sha256, signed_genesis_cbor)
             |> Base.encode32(case: :lower)
             |> String.slice(0..23)
             |> String.downcase()
  end

  def verify_json_to_did_hash(json, did) do
    did == genesis_to_did(json)
  end

  @spec verify_signature(map(), String.t()) :: boolean()
  def verify_signature(%{"sig" => sig} = operation, pubkey_to_verify_with) do
    {:ok, operation_cbor} =
      Map.delete(operation, "sig")
      |> DagCBOR.encode()

    K256.Signature.verify(
      sig
      |> Base.url_decode64!(case: :lower, padding: false)
      |> K256.Signature.create(),
      decode_did_key(pubkey_to_verify_with),
      operation_cbor
    )
  end

  def verify_genesis(%{"prev" => nil} = genesis, did) do
    verify_json_to_did_hash(genesis, did) &&
      verify_op_signature(
        genesis,
        get_genesis_pkeys(genesis)
      )
  end

  def verify_op_signature(op, pkeys) do
    pkeys
    |> Enum.any?(&verify_signature(op, &1))
  end

  def get_genesis_pkeys(%{"type" => "create", "recoveryKey" => key}), do: [key]
  def get_genesis_pkeys(%{"type" => "plc_operation", "rotationKeys" => keys}), do: keys

  def decode_did_key("did:key:" <> did_key) do
    did_key
    |> Multibase.decode!()
    |> Multicodec.codec_decode()
    |> case do
      {:ok, {pubkey, "secp256k1-pub"}} -> K256.PublicKey.decompress(pubkey)
      _ -> raise "Currently cannot handle p256 or other types of public keys, will add later"
    end
  end

  def decode_did_key(did_key), do: did_key

  def verify_genesis_of_did("" <> did, dir \\ "plc.directory") do
    HTTPoison.get!("https://#{dir}/#{did}/log/audit").body
    |> Jason.decode!()
    |> List.first()
    |> Map.get("operation")
    |> verify_genesis(did)
  end
end
