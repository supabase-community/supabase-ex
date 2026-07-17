defmodule Supabase.Fetcher.MultipartTest do
  use ExUnit.Case, async: true

  alias Supabase.Fetcher.Multipart

  # boundary comes back quoted in the content-type header, strip the quotes
  defp boundary(content_type) do
    [b] = Regex.run(~r/boundary="?([^"]+)"?/, content_type, capture: :all_but_first)
    b
  end

  describe "encode/1" do
    test "encodes an in-memory file part with its metadata" do
      parts = [
        {:file, "PDF-CONTENT",
         name: "doc", filename: "report.pdf", content_type: "application/pdf"}
      ]

      {content_type, body} = Multipart.encode(parts)
      body = IO.iodata_to_binary(body)

      assert content_type =~ "multipart/form-data; boundary="
      assert body =~ "--#{boundary(content_type)}"
      assert body =~ ~s(name="doc")
      assert body =~ ~s(filename="report.pdf")
      assert body =~ "application/pdf"
      assert body =~ "PDF-CONTENT"
    end

    test "in-memory file falls back to default filename and content-type" do
      {_ct, body} = Multipart.encode([{:file, "bytes", name: "doc"}])
      body = IO.iodata_to_binary(body)

      assert body =~ ~s(filename="file")
      assert body =~ "application/octet-stream"
    end

    test "encodes a text field" do
      {_ct, body} = Multipart.encode([{:field, "album", "Vacation 2025"}])
      body = IO.iodata_to_binary(body)

      assert body =~ ~s(name="album")
      assert body =~ "Vacation 2025"
    end

    test "text field with custom content-type" do
      {_ct, body} = Multipart.encode([{:field, "meta", "{}", content_type: "application/json"}])
      body = IO.iodata_to_binary(body)

      assert body =~ "application/json"
      assert body =~ "{}"
    end

    test "encodes multiple parts sharing one boundary" do
      parts = [
        {:file, "IMG", name: "photos", filename: "a.jpg", content_type: "image/jpeg"},
        {:field, "album", "trip"}
      ]

      {content_type, body} = Multipart.encode(parts)
      body = IO.iodata_to_binary(body)
      b = boundary(content_type)

      assert body =~ "--#{b}"
      assert body =~ "a.jpg"
      assert body =~ "album"
      # closing delimiter
      assert body =~ "--#{b}--"
    end

    test "raises on an invalid part shape" do
      assert_raise ArgumentError, ~r/Invalid multipart part/, fn ->
        Multipart.encode([{:not_a_part, "x"}])
      end
    end
  end

  describe "encode_stream/1" do
    test "returns a streamable body carrying the parts" do
      parts = [{:field, "album", "trip"}]
      {content_type, stream} = Multipart.encode_stream(parts)

      assert content_type =~ "multipart/form-data; boundary="
      body = stream |> Enum.to_list() |> IO.iodata_to_binary()

      assert body =~ ~s(name="album")
      assert body =~ "trip"
      assert body =~ "--#{boundary(content_type)}"
    end
  end

  describe "content_length/1" do
    test "returns byte size without a real request" do
      small = Multipart.content_length([{:file, "x", name: "f"}])
      big = Multipart.content_length([{:file, String.duplicate("x", 100), name: "f"}])

      assert is_integer(small) and small > 0
      assert big > small
    end
  end
end
