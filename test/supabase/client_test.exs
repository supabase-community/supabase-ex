defmodule Supabase.ClientTest do
  use ExUnit.Case, async: true

  alias Supabase.Client

  @valid_base_url "https://test.supabase.co"
  @valid_api_key "test_api_key"

  describe "Client struct defaults" do
    test "has default values for db, global, and auth fields" do
      client = %Client{}

      assert client.db.schema == "public"
      assert client.global.headers == %{}
      assert client.auth.auto_refresh_token == true
      assert client.auth.debug == false
      assert client.auth.detect_session_in_url == true
      assert client.auth.flow_type == :implicit
      assert client.auth.persist_session == true
      assert client.auth.storage_key == nil
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
end
