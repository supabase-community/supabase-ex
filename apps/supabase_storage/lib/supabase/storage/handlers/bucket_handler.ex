defmodule Supabase.Storage.BucketHandler do
  @moduledoc """
  Provides low-level API functions for managing Supabase Storage buckets.

  The `BucketHandler` module offers a collection of functions that directly interact with the Supabase Storage API for managing buckets. This module works closely with the `Supabase.Fetcher` for sending HTTP requests and the `Supabase.Storage.Cache` for caching bucket information.

  ## Features

  - **Bucket Listing**: Fetch a list of all the buckets available in the storage.
  - **Bucket Retrieval**: Retrieve detailed information about a specific bucket.
  - **Bucket Creation**: Create a new bucket with specified attributes.
  - **Bucket Update**: Modify the attributes of an existing bucket.
  - **Bucket Emptying**: Empty the contents of a bucket without deleting the bucket itself.
  - **Bucket Deletion**: Permanently remove a bucket and its contents.

  ## Caution

  This module provides a low-level interface to Supabase Storage buckets and is designed for internal use by the `Supabase.Storage` module. Direct use is discouraged unless you need to perform custom or unsupported actions that are not available through the higher-level API. Incorrect use can lead to unexpected results or data loss.

  ## Implementation Details

  All functions within the module expect a base URL, API key, and access token as their initial arguments, followed by any additional arguments required for the specific operation. Responses are usually in the form of `{:ok, result}` or `{:error, message}` tuples.
  """

  alias Supabase.Connection, as: Conn
  alias Supabase.Fetcher
  alias Supabase.Storage.Bucket
  alias Supabase.Storage.Cache
  alias Supabase.Storage.Endpoints

  @type bucket_id :: String.t()
  @type bucket_name :: String.t()
  @type create_attrs :: %{
          id: String.t(),
          name: String.t(),
          file_size_limit: integer | nil,
          allowed_mime_types: list(String.t()) | nil,
          public: boolean
        }
  @type update_attrs :: %{
          public: boolean | nil,
          file_size_limit: integer | nil,
          allowed_mime_types: list(String.t()) | nil
        }

  @spec list(Conn.base_url(), Conn.api_key(), Conn.access_token()) ::
          {:ok, [Bucket.t()]} | {:error, String.t()}
  def list(base_url, api_key, token) do
    url = Fetcher.get_full_url(base_url, Endpoints.bucket_path())
    headers = Fetcher.apply_headers(api_key, token)

    url
    |> Fetcher.get(headers)
    |> case do
      {:ok, body} -> {:ok, Enum.map(body, &Bucket.parse!/1)}
      {:error, msg} -> {:error, msg}
    end
  end

  @spec retrieve_info(Conn.base_url(), Conn.api_key(), Conn.access_token(), bucket_id) ::
          {:ok, Bucket.t()} | {:error, String.t()}
  def retrieve_info(base_url, api_key, token, bucket_id) do
    if bucket = Cache.find_bucket_by_id(bucket_id) do
      {:ok, bucket}
    else
      url = Fetcher.get_full_url(base_url, Endpoints.bucket_path_with_id(bucket_id))
      headers = Fetcher.apply_headers(api_key, token)

      url
      |> Fetcher.get(headers)
      |> case do
        {:ok, body} -> {:ok, Bucket.parse!(body)}
        {:error, msg} -> {:error, msg}
      end
    end
  end

  @spec create(Conn.base_url(), Conn.api_key(), Conn.access_token(), create_attrs) ::
          {:ok, Bucket.t()} | {:error, String.t()}
  def create(base_url, api_key, token, attrs) do
    url = Fetcher.get_full_url(base_url, Endpoints.bucket_path())
    headers = Fetcher.apply_headers(api_key, token)

    url
    |> Fetcher.post(attrs, headers)
    |> case do
      {:ok, resp} -> {:ok, resp}
      {:error, msg} -> {:error, msg}
    end
  end

  @spec update(Conn.base_url(), Conn.api_key(), Conn.access_token(), bucket_id, update_attrs) ::
          {:ok, Bucket.t()} | {:error, String.t()}
  def update(base_url, api_key, token, id, attrs) do
    url = Fetcher.get_full_url(base_url, Endpoints.bucket_path_with_id(id))
    headers = Fetcher.apply_headers(api_key, token)

    url
    |> Fetcher.put(attrs, headers)
    |> case do
      {:ok, message} -> {:ok, message}
      {:error, msg} -> {:error, msg}
    end
  end

  @spec empty(Conn.base_url(), Conn.api_key(), Conn.access_token(), bucket_id) ::
          {:ok, :successfully_emptied} | {:error, String.t()}
  def empty(base_url, api_key, token, id) do
    url = Fetcher.get_full_url(base_url, Endpoints.bucket_path_to_empty(id))
    headers = Fetcher.apply_headers(api_key, token)

    url
    |> Fetcher.post(nil, headers)
    |> case do
      {:ok, _message} -> {:ok, :successfully_emptied}
      {:error, msg} -> {:error, msg}
    end
  end

  @spec delete(Conn.base_url(), Conn.api_key(), Conn.access_token(), bucket_id) ::
          {:ok, String.t()} | {:error, String.t()}
  def delete(base_url, api_key, token, id) do
    url = Fetcher.get_full_url(base_url, Endpoints.bucket_path_with_id(id))
    headers = Fetcher.apply_headers(api_key, token)

    url
    |> Fetcher.delete(nil, headers)
    |> case do
      {:ok, body} -> {:ok, body}
      {:error, msg} -> {:error, msg}
    end
  end
end
