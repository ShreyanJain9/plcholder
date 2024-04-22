defmodule PlcholderDagcborTest do
  use ExUnit.Case
  doctest Plcholder.DagCBOR

  defp test_cases do
    [
      "test text",
      ["test text"],
      %{"string" => "test text"},
      %{"map" => %{"string" => "test text"}},
      %{"list" => ["text"]},
    ]
  end

  test "cbor roundtrip" do
    for input <- test_cases() do
      {:ok, cbor_encoded} = Plcholder.DagCBOR.encode(Jason.encode!(input))
      {:ok, original} = Plcholder.DagCBOR.decode(cbor_encoded)
      assert input == original
    end
  end
end
