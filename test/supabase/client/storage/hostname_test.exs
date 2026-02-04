defmodule Supabase.Client.Storage.HostnameTest do
  use ExUnit.Case, async: true

  alias Supabase.Client.Storage.Hostname

  doctest Supabase.Client.Storage.Hostname

  describe "transform_storage_url/1" do
    test "transforms .supabase.co domain to storage subdomain" do
      assert Hostname.transform_storage_url("https://abc123.supabase.co/storage/v1") ==
               "https://abc123.storage.supabase.co/storage/v1"
    end

    test "transforms .supabase.in domain to storage subdomain" do
      assert Hostname.transform_storage_url("https://project.supabase.in/storage/v1") ==
               "https://project.storage.supabase.in/storage/v1"
    end

    test "transforms .supabase.red domain to storage subdomain" do
      assert Hostname.transform_storage_url("https://xyz789.supabase.red/storage/v1") ==
               "https://xyz789.storage.supabase.red/storage/v1"
    end

    test "skips URLs that already have storage subdomain (.co)" do
      url = "https://abc123.storage.supabase.co/storage/v1"
      assert Hostname.transform_storage_url(url) == url
    end

    test "skips URLs that already have storage subdomain (.in)" do
      url = "https://project.storage.supabase.in/storage/v1"
      assert Hostname.transform_storage_url(url) == url
    end

    test "skips URLs that already have storage subdomain (.red)" do
      url = "https://xyz.storage.supabase.red/storage/v1"
      assert Hostname.transform_storage_url(url) == url
    end

    test "leaves custom domains unchanged" do
      url = "https://custom-domain.example.com/storage/v1"
      assert Hostname.transform_storage_url(url) == url
    end

    test "leaves localhost URLs unchanged" do
      url = "http://localhost:54321/storage/v1"
      assert Hostname.transform_storage_url(url) == url
    end

    test "leaves IP address URLs unchanged" do
      url = "http://127.0.0.1:54321/storage/v1"
      assert Hostname.transform_storage_url(url) == url
    end

    test "preserves URL path when transforming" do
      assert Hostname.transform_storage_url("https://test.supabase.co/storage/v1/bucket/file.png") ==
               "https://test.storage.supabase.co/storage/v1/bucket/file.png"
    end

    test "preserves query parameters when transforming" do
      assert Hostname.transform_storage_url("https://test.supabase.co/storage/v1?token=abc") ==
               "https://test.storage.supabase.co/storage/v1?token=abc"
    end

    test "preserves URL fragment when transforming" do
      assert Hostname.transform_storage_url("https://test.supabase.co/storage/v1#section") ==
               "https://test.storage.supabase.co/storage/v1#section"
    end

    test "handles HTTP (non-HTTPS) URLs" do
      assert Hostname.transform_storage_url("http://test.supabase.co/storage/v1") ==
               "http://test.storage.supabase.co/storage/v1"
    end

    test "handles URL with port" do
      url = "https://test.supabase.co:443/storage/v1"
      result = Hostname.transform_storage_url(url)
      assert String.contains?(result, "storage.supabase.co")
    end

    test "returns nil when given nil" do
      assert Hostname.transform_storage_url(nil) == nil
    end

    test "returns empty string when given empty string" do
      assert Hostname.transform_storage_url("") == ""
    end

    test "handles URL without path" do
      assert Hostname.transform_storage_url("https://test.supabase.co") ==
               "https://test.storage.supabase.co"
    end

    test "handles URL with only root path" do
      assert Hostname.transform_storage_url("https://test.supabase.co/") ==
               "https://test.storage.supabase.co/"
    end

    test "handles subdomain with hyphens" do
      assert Hostname.transform_storage_url("https://my-project-123.supabase.co/storage/v1") ==
               "https://my-project-123.storage.supabase.co/storage/v1"
    end

    test "handles subdomain with numbers" do
      assert Hostname.transform_storage_url("https://123project.supabase.co/storage/v1") ==
               "https://123project.storage.supabase.co/storage/v1"
    end

    test "does not transform non-Supabase TLDs" do
      url = "https://project.supabase.com/storage/v1"
      assert Hostname.transform_storage_url(url) == url
    end

    test "does not transform partial matches" do
      url = "https://mysupabase.co/storage/v1"
      assert Hostname.transform_storage_url(url) == url
    end
  end
end
