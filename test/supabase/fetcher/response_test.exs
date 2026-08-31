defmodule Supabase.Fetcher.ResponseTest do
  use ExUnit.Case, async: true

  alias Supabase.Fetcher.Response

  describe "get_header/2" do
    setup do
      resp = %Response{
        status: 200,
        headers: [{"Content-Type", "application/json"}, {"x-custom", "1"}],
        body: nil
      }

      {:ok, resp: resp}
    end

    test "finds headers case-insensitively", %{resp: resp} do
      assert Response.get_header(resp, "content-type") == "application/json"
      assert Response.get_header(resp, "Content-Type") == "application/json"
      assert Response.get_header(resp, "CONTENT-TYPE") == "application/json"
      assert Response.get_header(resp, "X-Custom") == "1"
    end

    test "returns nil for missing headers", %{resp: resp} do
      assert Response.get_header(resp, "missing") == nil
    end

    test "get_header/3 falls back to default", %{resp: resp} do
      assert Response.get_header(resp, "missing", "fallback") == "fallback"
      assert Response.get_header(resp, "content-type", "fallback") == "application/json"
    end
  end
end
