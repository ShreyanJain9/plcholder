defmodule PlcholderK256Test do
  use ExUnit.Case
  doctest Plcholder.K256
  alias Plcholder.K256, as: K256

  defp test_cases do
    %{
      "9085d2bef69286a6cbb51623c8fa258629945cd55ca705cc4e66700396894e0c" =>
        "did:key:zQ3shokFTS3brHcDQrn82RUDfCZESWL1ZdCEJwekUDPQiYBme",
      "f0f4df55a2b3ff13051ea814a8f24ad00f2e469af73c363ac7e9fb999a9072ed" =>
        "did:key:zQ3shtxV1FrJfhqE1dvxYRcCknWNjHc3c5X1y3ZSoPDi2aur2",
      "6b0b91287ae3348f8c2f2552d766f30e3604867e34adc37ccbb74a8e6b893e02" =>
        "did:key:zQ3shZc2QzApp2oymGvQbzP8eKheVshBHbU4ZYjeXqwSKEn6N",
      "c0a6a7c560d37d7ba81ecee9543721ff48fea3e0fb827d42c1868226540fac15" =>
        "did:key:zQ3shadCps5JLAHcZiuX5YUtWHHL8ysBJqFLWvjZDKAWUBGzy",
      "175a232d440be1e0788f25488a73d9416c04b6f924bea6354bf05dd2f1a75133" =>
        "did:key:zQ3shptjE6JwdkeKN4fcpnYQY3m9Cet3NiHdAfpvSUZBFoKBj"
    }
  end

  test "derives correct did:key" do
    for {privkey_hex, expected_did} <- test_cases() do
      assert privkey_hex
             |> K256.PrivateKey.from_hex()
             |> K256.PrivateKey.to_pubkey()
             |> K256.PublicKey.to_did_key() == expected_did
    end
  end

  test "signing and verifying" do
    # Just having each key signing its did:key: for now

    for {privkey_hex, message_to_sign} <- test_cases() do
      signature =
        privkey_hex
        |> K256.PrivateKey.from_hex()
        |> K256.PrivateKey.sign(message_to_sign)

      pubkey =
        privkey_hex
        |> K256.PrivateKey.from_hex()
        |> K256.PrivateKey.to_pubkey()

      assert K256.Signature.verify(signature, pubkey, message_to_sign) |> elem(0) == :ok
    end
  end
end
