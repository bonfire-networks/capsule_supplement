defmodule Capsule.Storages.DiskTest do
  use ExUnit.Case
  doctest Capsule

  alias Capsule.Storages.Disk
  alias Capsule.MockUpload

  describe "put/1" do
    test "returns success tuple" do
      assert {:ok, _} = Disk.put(%MockUpload{})

      on_exit(fn -> File.rm!("tmp/hi") end)
    end

    test "writes file to path from name" do
      Disk.put(%MockUpload{name: "subdir/name"})

      assert File.exists?("tmp/subdir/name")

      on_exit(fn -> File.rm!("tmp/subdir/name") end)
    end

    test "writes file to path with prefix" do
      Disk.put(%MockUpload{name: "name"}, prefix: "subdir")

      assert File.exists?("tmp/subdir/name")

      on_exit(fn -> File.rm!("tmp/subdir/name") end)
    end

    test "returns error when file already exists" do
      File.write!("tmp/name", "data")

      assert {:error, _} = Disk.put(%MockUpload{name: "name"})

      on_exit(fn -> File.rm!("tmp/name") end)
    end

    test "overwrites existing file when force is set to true" do
      file = "tmp/name"

      File.write!(file, "data")

      Disk.put(%MockUpload{name: "name", content: "new", path: file}, force: true)

      assert "new" = File.read!(file)

      on_exit(fn -> File.rm!(file) end)
    end
  end

  describe "read/1" do
    test "returns success tuple with data" do
      File.write!("tmp/path", "data")

      assert {:ok, "data"} = Disk.read("path")

      on_exit(fn -> File.rm!("tmp/path") end)
    end
  end

  describe "copy/1" do
    test "returns success tuple with data" do
      File.write!("tmp/path", "data")

      assert {:ok, "new_path"} = Disk.copy("/path", "new_path")

      on_exit(fn -> File.rm!("tmp/new_path") end)
    end

    test "creates path" do
      File.write!("tmp/path", "data")

      assert {:ok, "subdir/new_path"} = Disk.copy("path", "subdir/new_path")

      on_exit(fn -> File.rm!("tmp/subdir/new_path") end)
    end
  end
end
