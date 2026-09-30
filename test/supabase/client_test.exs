defmodule Supabase.ClientTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias Supabase.Client

  @valid_base_url "https://test.supabase.co"
  @valid_api_key "test_api_key"

  describe "Client struct defaults" do
    test "has default values for db, global and auth fields" do
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

    test "has default values for db request pipeline options" do
      client = %Client{}

      assert client.db.timeout == nil
      assert client.db.url_length_limit == 8000
    end
  end

  def token_fn, do: "mfa-token"

  describe "access_token_fn" do
    test "accepts a 0-arity function" do
      {:ok, client} =
        Supabase.init_client(@valid_base_url, @valid_api_key, %{
          access_token_fn: fn -> "dynamic-token" end
        })

      assert Client.resolve_access_token(client) == "dynamic-token"
    end

    test "accepts an MFA tuple" do
      {:ok, client} =
        Supabase.init_client(@valid_base_url, @valid_api_key, %{
          access_token_fn: {__MODULE__, :token_fn, []}
        })

      assert Client.resolve_access_token(client) == "mfa-token"
    end

    test "rejects an invalid access_token_fn" do
      assert {:error, changeset} =
               Supabase.init_client(@valid_base_url, @valid_api_key, %{
                 access_token_fn: "not-a-function"
               })

      assert %{access_token_fn: [_ | _]} = errors_on(changeset)
    end

    test "resolves a static access token when no function is set" do
      {:ok, client} = Supabase.init_client(@valid_base_url, @valid_api_key)

      assert client.access_token_fn == nil
      assert Client.resolve_access_token(client) == @valid_api_key
    end
  end

  describe "db request pipeline options" do
    test "casts timeout and url_length_limit" do
      {:ok, client} =
        Supabase.init_client(@valid_base_url, @valid_api_key,
          db: %{timeout: 5_000, url_length_limit: 100}
        )

      assert client.db.timeout == 5_000
      assert client.db.url_length_limit == 100
    end

    test "rejects non-positive timeout" do
      assert {:error, changeset} =
               Supabase.init_client(@valid_base_url, @valid_api_key, db: %{timeout: 0})

      assert %{db: %{timeout: [_ | _]}} = errors_on(changeset)
    end
  end

  describe "new-format API keys" do
    test "new_format_key?/1 recognizes publishable and secret keys" do
      assert Client.new_format_key?("sb_publishable_abc123")
      assert Client.new_format_key?("sb_secret_abc123")
      refute Client.new_format_key?("sb_other_abc123")
      refute Client.new_format_key?("eyJhbGciOiJIUzI1NiJ9.legacy-jwt")
      refute Client.new_format_key?(nil)
    end

    test "unrecognized_sb_key?/1 flags unknown sb_ subtypes only" do
      assert Client.unrecognized_sb_key?("sb_other_abc123")
      refute Client.unrecognized_sb_key?("sb_publishable_abc123")
      refute Client.unrecognized_sb_key?("sb_secret_abc123")
      refute Client.unrecognized_sb_key?("legacy-anon-key")
      refute Client.unrecognized_sb_key?(nil)
    end

    test "warns once per distinct unrecognized sb_ key on init" do
      log =
        capture_log([level: :warning], fn ->
          {:ok, _client} = Supabase.init_client(@valid_base_url, "sb_other_abc123")
        end)

      assert log =~ "not a recognized new-format key"
      assert length(String.split(log, "not a recognized new-format key")) == 2
    end

    test "does not warn for recognized or legacy keys" do
      log =
        capture_log([level: :warning], fn ->
          {:ok, _} = Supabase.init_client(@valid_base_url, "sb_publishable_abc123")
          {:ok, _} = Supabase.init_client(@valid_base_url, "legacy-anon-key")
        end)

      refute log =~ "not a recognized new-format key"
    end
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
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
    for tld <- ~w(co in red) do
      test "transforms storage URL (.#{tld} domain)" do
        tld = unquote(tld)

        {:ok, client} =
          Supabase.init_client(
            "https://project.supabase.#{tld}",
            @valid_api_key,
            storage: %{use_new_hostname: true}
          )

        assert client.storage_url == "https://project.storage.supabase.#{tld}/storage/v1"
      end
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
