defmodule Plcholder.Multicodec do
  use GenServer

  alias Matcha.Table.ETS
  require ETS
  @moduledoc """
  # Multicodec
  [Multicodec](https://github.com/multiformats/multicodec) is one of the Multiformats used in IPFS and,
  especially in the context of ATProto, IPLD.
  It's used in places like CIDs to help describe binary data using a varint at the beginning of the data.
  Basically, it's an agreed-upon codec table. You can find each codec and its integer code in
  `multicodec.csv`.

  # The CSV file
  `multicodec.csv`, which can be found at the toplevel of the repository, is a CSV file
  that is slightly modified from the original [`table.csv`](https://github.com/multiformats/multicodec/blob/master/table.csv).
  It removes the `description` column, as well as the top header row which is usually used by CSV
  to denote column names. This isn't necessary, but it does keep the parser logic simpler.

  # Why is this a GenServer?
  It doesn't have to be, but it felt more natural to read the CSV once at runtime
  when the GenServer is started and then use the multicodec map in subsequent calls.
  The alternative would be to read the CSV in every call,
  which felt wasteful, and felt side-effect-ful, or to have the codec table hard-coded
  as a module attribute, which felt unwieldy, especially when the CSV is *right there*. In theory, that
  could have been done through compile-time metaprogramming, but... meh, this approach works fine,
  and it's easier to understand.
  """

  @type multi_codec() :: any()

  def start_link(multicodec_csv) do
    GenServer.start_link(__MODULE__, multicodec_csv, name: __MODULE__)
  end

  @impl GenServer
  def init(csv_path) do
    {:ok,
     csv_path
     |> File.stream!()
     |> read_csv()
     |> load_into_ets()
    }
  end

  @doc """
  Reads the CSV file and returns a map of multicodec names to integer codes.
  """
  def read_csv(%File.Stream{} = csv) do
    csv
    |> Stream.map(&String.replace(&1, " ", ""))
    |> Stream.map(&String.split(&1, ",", trim: true))
    |> Enum.reduce(%{}, fn [name, _tag, "0x" <> code, _status], acc ->
      Map.put(acc, String.to_atom(name), Integer.parse(code, 16) |> elem(0))
    end)
  end

  defp load_into_ets(multicodec_map) do
    tab = :ets.new(__MODULE__, [:set, :public, :named_table])
    for {codec, code} <- multicodec_map do
      :ets.insert(__MODULE__, {codec, code})
    end
    tab
  end


  @spec bytes_to_codec(integer()) :: atom() | []
  @doc """
  For the given integer code, returns the codec name.
  """
  def bytes_to_codec(bytes) do
    ETS.select __MODULE__ do
      {codec, code} when code == bytes -> codec
    end
    |> List.first
  end

  def codec_to_bytes(codec) do
    ETS.select __MODULE__ do
      {codec, code} when codec == codec -> code
    end
    |> List.first
  end

  @doc """
  Encodes a binary with the given codec by appending the varint-encoded integer code
  for that codec to the beginning of the binary.
  """
  def encode!(bytes, "" <> codec) do
    <<Varint.LEB128.encode(
        codec_to_bytes(String.to_atom(codec))
      )::binary, bytes::binary>>
  end

  def encode!(bytes, codec) do
    encode!(bytes, to_string(codec))
  end

  @spec encode(binary(), String.t() | atom()) ::
          {:error, any()} | {:ok, binary()}
  @doc """
  Like `encode!/2`, but returns an error tuple instead of raising an exception, and {:ok, binary()} if successful.
  """
  def encode(b, c) do
    try do
      {:ok, encode!(b, c)}
    catch
      _, e -> {:error, e}
    end
  end

  @doc """
  Decodes a binary with the given codec by removing the varint-encoded integer code
  for that codec from the beginning of the binary. Returns a tuple in the form
  `{:ok, {rest_of_binary, codec_name}}`.
  """
  def codec_decode("" <> encoded) do
    try do
      with {prefix, rest} <- Varint.LEB128.decode(<<encoded::binary>>),
           codec when is_atom(codec) <- bytes_to_codec(prefix),
           do: {:ok, {rest, to_string(codec)}}
    catch
      _, e -> {:error, e}
    end
  end

  @doc """
  Given the name of a codec, returns whether it is supported or not.
  """
  @spec codec?(binary()) :: boolean()
  def codec?("" <> codec) do
    :ets.member(__MODULE__, String.to_atom(codec))
  end

  @doc """
  Returns a list of supported codec names.
  """
  @spec codecs() :: [String.t()]
  def codecs do
    :ets.tab2list(__MODULE__)
    |> Stream.map(&elem(&1, 0))
    |> Enum.map(&to_string/1)
  end
end
