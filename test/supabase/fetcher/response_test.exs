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

  describe "decode_body/3 with the default JSON decoder" do
    defp resp(body, headers \\ []) do
      %Response{status: 200, headers: headers, body: body}
    end

    test "empty bodies decode to nil" do
      assert {:ok, %{body: nil}} = Response.decode_body(resp(""))
      assert {:ok, %{body: nil}} = Response.decode_body(resp(nil))
    end

    test "decodes JSON bodies" do
      headers = [{"content-type", "application/json; charset=utf-8"}]
      assert {:ok, %{body: %{"a" => 1}}} = Response.decode_body(resp(~s({"a":1}), headers))
    end

    test "passes non-JSON content-type bodies through untouched" do
      headers = [{"content-type", "text/csv"}]
      assert {:ok, %{body: "a,b\n1,2"}} = Response.decode_body(resp("a,b\n1,2", headers))
    end

    test "falls back to raw body when no content-type and not JSON" do
      assert {:ok, %{body: "plain text"}} = Response.decode_body(resp("plain text"))
    end

    test "invalid JSON with JSON content-type returns a Supabase.Error" do
      headers = [{"content-type", "application/json"}]
      assert {:error, %Supabase.Error{code: :invalid_json_body}} =
               Response.decode_body(resp("{oops", headers))
    end
  end
end
