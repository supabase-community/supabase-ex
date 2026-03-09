defmodule Supabase.ClientTest do
  use ExUnit.Case, async: true

  alias Supabase.Client

  @valid_base_url "https://test.supabase.co"
  @valid_api_key "test_api_key"

  describe "Client struct defaults" do
    test "has default values for db, global, auth, and storage fields" do
      client = %Client{}

      assert client.db.schema == "public"
      assert client.global.headers == %{}
      assert client.auth.auto_refresh_token == true
      assert client.auth.debug == false
      assert client.auth.detect_session_in_url == true
      assert client.auth.flow_type == :implicit
      assert client.auth.persist_session == true
      assert client.auth.storage_key == nil
      assert client.storage.use_new_hostname == false
    end
  end

  defmodule TestClient do
    use Supabase.Client, otp_app: :supabase_potion
  end

  describe "client definition" do
    setup do
      config = [
        base_url: @valid_base_url,
        api_key: @valid_api_key,
        access_token: "123",
        auth: %{storage_key: "test-key", debug: true}
      ]

      Application.put_env(:supabase_potion, TestClient, config)
      :ok
    end

    test "retrieves client" do
      assert %Client{} = client = TestClient.get_client!()
      assert client.base_url == @valid_base_url
      assert client.api_key == @valid_api_key
      assert client.access_token == "123"
      assert client.auth.debug
      assert client.auth.storage_key == "test-key"
    end

    test "updates access token in client" do
      new_access_token = "new_access_token"
      assert %Client{} = client = TestClient.get_client!()
      assert client.access_token == "123"
      assert %Client{} = client = TestClient.set_auth!(new_access_token)
      assert client.access_token == new_access_token
    end
  end

  describe "Storage configuration" do
    test "uses default storage URL when use_new_hostname is false" do
      {:ok, client} = Supabase.init_client(@valid_base_url, @valid_api_key)

      assert client.storage_url == "https://test.supabase.co/storage/v1"
      assert client.storage.use_new_hostname == false
    end

    test "transforms storage URL when use_new_hostname is true (.co domain)" do
      {:ok, client} =
        Supabase.init_client(
          "https://project.supabase.co",
          @valid_api_key,
          storage: %{use_new_hostname: true}
        )

      assert client.storage_url == "https://project.storage.supabase.co/storage/v1"
      assert client.storage.use_new_hostname == true
    end

    test "transforms storage URL when use_new_hostname is true (.in domain)" do
      {:ok, client} =
        Supabase.init_client(
          "https://project.supabase.in",
          @valid_api_key,
          storage: %{use_new_hostname: true}
        )

      assert client.storage_url == "https://project.storage.supabase.in/storage/v1"
    end

    test "transforms storage URL when use_new_hostname is true (.red domain)" do
      {:ok, client} =
        Supabase.init_client(
          "https://project.supabase.red",
          @valid_api_key,
          storage: %{use_new_hostname: true}
        )

      assert client.storage_url == "https://project.storage.supabase.red/storage/v1"
    end

    test "accepts storage config as keyword list" do
      {:ok, client} =
        Supabase.init_client(
          "https://project.supabase.co",
          @valid_api_key,
          storage: [use_new_hostname: true]
        )

      assert client.storage_url == "https://project.storage.supabase.co/storage/v1"
    end

    test "leaves custom domains unchanged even with use_new_hostname true" do
      {:ok, client} =
        Supabase.init_client(
          "https://custom-domain.example.com",
          @valid_api_key,
          storage: %{use_new_hostname: true}
        )

      assert client.storage_url == "https://custom-domain.example.com/storage/v1"
    end

    test "leaves localhost unchanged even with use_new_hostname true" do
      {:ok, client} =
        Supabase.init_client(
          "http://localhost:54321",
          @valid_api_key,
          storage: %{use_new_hostname: true}
        )

      assert client.storage_url == "http://localhost:54321/storage/v1"
    end

    test "does not transform URL when already has storage subdomain" do
      {:ok, client} =
        Supabase.init_client(
          "https://project.storage.supabase.co",
          @valid_api_key,
          storage: %{use_new_hostname: true}
        )

      # Should remain unchanged
      assert client.storage_url == "https://project.storage.supabase.co/storage/v1"
    end

    test "works with complex project IDs" do
      {:ok, client} =
        Supabase.init_client(
          "https://my-project-123.supabase.co",
          @valid_api_key,
          storage: %{use_new_hostname: true}
        )

      assert client.storage_url == "https://my-project-123.storage.supabase.co/storage/v1"
    end
  end
end
