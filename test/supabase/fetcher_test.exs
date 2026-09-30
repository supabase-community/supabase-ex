defmodule Supabase.FetcherTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog
  import Mox

  alias Supabase.Fetcher
  alias Supabase.Fetcher.Request

  setup :verify_on_exit!

  setup do
    Application.put_env(:supabase_potion, :http_client, Supabase.TestHTTPAdapter)
    on_exit(fn -> Application.delete_env(:supabase_potion, :http_client) end)
    :ok
  end

  defp ok_response do
    %Finch.Response{
      status: 200,
      headers: [{"content-type", "application/json"}],
      body: "{}"
    }
  end

  defp build(client) do
    client
    |> Request.new()
    |> Request.with_auth_url("/token")
  end

  describe "db.timeout" do
    test "is injected as receive_timeout into adapter opts" do
      client =
        Supabase.init_client!("http://127.0.0.1:54321", "test-api", db: %{timeout: 5_000})

      expect(Supabase.TestHTTPAdapter, :request, fn _builder, opts ->
        assert opts[:receive_timeout] == 5_000
        {:ok, ok_response()}
      end)

      assert {:ok, _} = Fetcher.request(build(client))
    end

    test "per-call opts win over db.timeout" do
      client =
        Supabase.init_client!("http://127.0.0.1:54321", "test-api", db: %{timeout: 5_000})

      expect(Supabase.TestHTTPAdapter, :request, fn _builder, opts ->
        assert opts[:receive_timeout] == 1_000
        {:ok, ok_response()}
      end)

      assert {:ok, _} = Fetcher.request(build(client), receive_timeout: 1_000)
    end

    test "is not injected when not configured" do
      client = Supabase.init_client!("http://127.0.0.1:54321", "test-api")

      expect(Supabase.TestHTTPAdapter, :request, fn _builder, opts ->
        refute Keyword.has_key?(opts, :receive_timeout)
        {:ok, ok_response()}
      end)

      assert {:ok, _} = Fetcher.request(build(client))
    end
  end

  describe "db.url_length_limit" do
    test "warns when the request URL exceeds the limit" do
      client =
        Supabase.init_client!("http://127.0.0.1:54321", "test-api",
          db: %{url_length_limit: 10}
        )

      stub(Supabase.TestHTTPAdapter, :request, fn _builder, _opts -> {:ok, ok_response()} end)

      log = capture_log([level: :warning], fn -> Fetcher.request(build(client)) end)

      assert log =~ "url_length_limit"
    end

    test "does not warn when the URL fits the limit" do
      client = Supabase.init_client!("http://127.0.0.1:54321", "test-api")

      stub(Supabase.TestHTTPAdapter, :request, fn _builder, _opts -> {:ok, ok_response()} end)

      log = capture_log([level: :warning], fn -> Fetcher.request(build(client)) end)

      refute log =~ "url_length_limit"
    end

    test "does not warn when the limit is disabled" do
      client =
        Supabase.init_client!("http://127.0.0.1:54321", "test-api",
          db: %{url_length_limit: nil}
        )

      stub(Supabase.TestHTTPAdapter, :request, fn _builder, _opts -> {:ok, ok_response()} end)

      log = capture_log([level: :warning], fn -> Fetcher.request(build(client)) end)

      refute log =~ "url_length_limit"
    end
  end
end
