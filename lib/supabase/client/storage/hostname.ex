defmodule Supabase.Client.Storage.Hostname do
  @moduledoc """
  Handles hostname transformation for storage subdomain routing.

  This module transforms official Supabase domain URLs to use the storage-specific
  subdomain, which is optimized for large file uploads (>50GB) and provides better
  streaming performance.

  ## Transformation Rules

  - Official Supabase domains (`.supabase.co`, `.supabase.in`, `.supabase.red`) are
    transformed to use the `storage.supabase.*` subdomain
  - URLs already containing `storage.supabase.` are left unchanged
  - Custom domains (non-Supabase) are left untouched
  - Localhost and IP addresses are left unchanged

  ## Examples

      iex> Supabase.Client.Storage.Hostname.transform_storage_url("https://abc123.supabase.co/storage/v1")
      "https://abc123.storage.supabase.co/storage/v1"

      iex> Supabase.Client.Storage.Hostname.transform_storage_url("https://abc123.supabase.in/storage/v1")
      "https://abc123.storage.supabase.in/storage/v1"

      iex> Supabase.Client.Storage.Hostname.transform_storage_url("https://abc123.storage.supabase.co/storage/v1")
      "https://abc123.storage.supabase.co/storage/v1"

      iex> Supabase.Client.Storage.Hostname.transform_storage_url("https://custom-domain.com/storage/v1")
      "https://custom-domain.com/storage/v1"

      iex> Supabase.Client.Storage.Hostname.transform_storage_url("http://localhost:54321/storage/v1")
      "http://localhost:54321/storage/v1"

  """

  @supabase_domain_regex ~r/\.supabase\.(co|in|red)$/
  @storage_subdomain_regex ~r/storage\.supabase\./

  @doc """
  Transforms a storage URL to use the storage subdomain if applicable.

  This function only transforms official Supabase domains that don't already
  have the storage subdomain. Custom domains and non-Supabase URLs are returned
  unchanged.

  ## Parameters

    - `storage_url` - The storage URL to transform (string)

  ## Returns

  The transformed URL as a string. If transformation is not applicable,
  returns the original URL unchanged.

  ## Examples

      iex> Supabase.Client.Storage.Hostname.transform_storage_url("https://project.supabase.co/storage/v1")
      "https://project.storage.supabase.co/storage/v1"

      iex> Supabase.Client.Storage.Hostname.transform_storage_url("https://project.storage.supabase.co/storage/v1")
      "https://project.storage.supabase.co/storage/v1"

      iex> Supabase.Client.Storage.Hostname.transform_storage_url("https://custom.example.com/storage/v1")
      "https://custom.example.com/storage/v1"

      iex> Supabase.Client.Storage.Hostname.transform_storage_url(nil)
      nil

  """
  @spec transform_storage_url(String.t() | nil) :: String.t() | nil
  def transform_storage_url(nil), do: nil
  def transform_storage_url(""), do: ""

  def transform_storage_url(storage_url) when is_binary(storage_url) do
    uri = URI.parse(storage_url)

    if should_transform?(uri) do
      new_host = transform_hostname(uri.host)
      %{uri | host: new_host} |> URI.to_string()
    else
      storage_url
    end
  end

  # Private helper functions

  defp should_transform?(%URI{host: host}) when is_binary(host) do
    supabase_domain?(host) and not has_storage_subdomain?(host)
  end

  defp should_transform?(_), do: false

  defp supabase_domain?(hostname) when is_binary(hostname) do
    Regex.match?(@supabase_domain_regex, hostname)
  end

  defp supabase_domain?(_), do: false

  defp has_storage_subdomain?(hostname) when is_binary(hostname) do
    Regex.match?(@storage_subdomain_regex, hostname)
  end

  defp has_storage_subdomain?(_), do: false

  defp transform_hostname(hostname) when is_binary(hostname) do
    String.replace(hostname, "supabase.", "storage.supabase.", global: false)
  end
end
