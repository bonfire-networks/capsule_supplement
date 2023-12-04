defmodule Capsule.Storages.RAM do
  alias Capsule.{Storage, Upload}

  @behaviour Storage

  @impl Storage
  def put(upload, _opts \\ []) do
    {:ok, contents} = Upload.contents(upload)

    {:ok, pid} = StringIO.open(contents)

    serialized_pid =
      pid
      |> :erlang.term_to_binary()
      |> Base.url_encode64()

    {:ok, Path.join(serialized_pid, Upload.name(upload))}
  end

  def clone(id, dest_path, _opts \\ []) do
    [serialized_pid, _] = decompose_id(id)

    {:ok, Path.join(serialized_pid, dest_path)}
  end

  @impl Storage
  def delete(id, _opts \\ []) when is_binary(id) do
    pid = decode_pid!(id)

    {:ok, _} = StringIO.close(pid)

    :ok
  end

  @impl Storage
  def stream(id, _opts \\ []),
    do: {:ok, id |> decode_pid! |> IO.binstream(512)}

  @impl Storage
  def read(id, _opts \\ []),
    do: {:ok, id |> decode_pid! |> StringIO.contents() |> elem(0)}

  @impl Storage
  def url(_path, _opts \\ []), do: nil

  @impl Storage
  def path(_path, _opts \\ []), do: nil

  defp decompose_id(id), do: String.split(id, "/", parts: 2)

  defp decode_pid!(id) do
    id
    |> decompose_id
    |> List.first()
    |> Base.url_decode64!()
    |> :erlang.binary_to_term()
  end
end
