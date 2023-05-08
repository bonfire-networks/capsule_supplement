defmodule Capsule.Storages.Disk do
  alias Capsule.{Storage, Upload, Encapsulation}

  @behaviour Storage

  @impl Storage
  def put(upload, opts \\ []) do
    with path <- Path.join(opts[:prefix] || "/", Upload.name(upload)),
         destination <- path_in_root(opts, path),
         true <-
           !File.exists?(destination) || opts[:force] ||
             {:error, "File already exists at upload destination"},
         {:ok, contents} <- Upload.contents(upload) do
      create_path!(destination)

      File.write!(destination, contents)

      encapsulation = %Encapsulation{
        id: path,
        size: byte_size(contents),
        storage: to_string(__MODULE__)
      }

      {:ok, encapsulation}
    end
    |> case do
      {:error, error} ->
        {:error, "Could not store file: #{error}"}

      success_tuple ->
        success_tuple
    end
  end

  @impl Storage
  def copy(%Encapsulation{id: id} = encapsulation, path, opts \\ []) do
    path_in_root(opts, path)
    |> create_path!

    path_in_root(opts, id)
    |> File.cp(path_in_root(opts, path))
    |> case do
      :ok -> {:ok, encapsulation |> Map.replace!(:id, path)}
      error_tuple -> error_tuple
    end
  end

  @impl Storage
  def delete(%Encapsulation{id: id}, opts \\ []) when is_binary(id) do
    path_in_root(opts, id)
    |> File.rm()
    |> case do
      :ok -> :ok
      {:error, error} -> {:error, "Could not remove file: #{error}"}
    end
  end

  @impl Storage
  def read(%Encapsulation{id: id}, opts \\ []), do: path_in_root(opts, id) |> File.read()

  defp config(opts, key) do
    Application.fetch_env!(:capsule, __MODULE__)
    |> Keyword.merge(opts)
    |> Keyword.fetch!(key)
  end

  defp path_in_root(opts, path) do
    config(opts, :root_dir)
    |> Path.join(path)
  end

  defp create_path!(path) do
    path |> Path.dirname() |> File.mkdir_p!()
  end
end
