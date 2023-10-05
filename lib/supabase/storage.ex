defmodule Supabase.Storage do
  @moduledoc """
  Supabase.Storage Elixir Package

  This module provides integration with the Supabase Storage API, enabling developers
  to perform a multitude of operations related to buckets and objects with ease.

  ## Features

  1. **Bucket Operations**: Methods that allow the creation, listing, and removal of buckets.
  2. **Object Operations**: Functions designed to upload, download, retrieve object information,
     and perform move, copy, and remove actions on objects.

  ## Usage

  You can start by creating or managing buckets:

      Supabase.Storage.create_bucket(client, "my_new_bucket")

  Once a bucket is set up, objects within the bucket can be managed:

      Supabase.Storage.upload_object(client, "my_bucket", "path/on/server.png", "path/on/local.png")

  ## Examples

  Here are some basic examples:

      # Removing an object
      Supabase.Storage.remove_object(client, "my_bucket", "path/on/server.png")

      # Moving an object
      Supabase.Storage.move_object(client, "my_bucket", "path/on/server1.png", "path/on/server2.png")

  Ensure to refer to method-specific documentation for detailed examples and explanations.

  ## Permissions

  Do remember to check and set the appropriate permissions in Supabase to make sure that the
  operations can be performed without any hitches.
  """

  import Supabase.Client, only: [is_client: 1]

  alias Supabase.Client
  alias Supabase.Client.Conn
  alias Supabase.Storage.Bucket
  alias Supabase.Storage.BucketHandler
  alias Supabase.Storage.Object
  alias Supabase.Storage.ObjectHandler
  alias Supabase.Storage.ObjectOptions
  alias Supabase.Storage.SearchOptions

  @behaviour Supabase.StorageBehaviour

  @doc """
  Retrieves information about all buckets in the current project.

  ## Notes

  * Policy permissions required
    * `buckets` permissions: `select`
    * `objects` permissions: none

  ## Examples

      iex> Supabase.Storage.list_buckets(client)
      {:ok, [%Supabase.Storage.Bucket{...}, ...]}

      iex> Supabase.Storage.list_buckets(invalid_conn)
      {:error, reason}

  """
  @impl true
  def list_buckets(client) when is_client(client) do
    case Client.retrieve_connection(client) do
      nil ->
        {:error, :invalid_client}

      %Conn{access_token: token, api_key: api_key, base_url: base_url} ->
        {:ok, BucketHandler.list(base_url, api_key, token)}
    end
  end

  @doc """
  Retrieves information about a bucket in the current project.

  ## Notes

  * Policy permissions required
    * `buckets` permissions: `select`
    * `objects` permissions: none

  ## Examples

      iex> Supabase.Storage.retrieve_bucket_info(client, "avatars")
      {:ok, %Supabase.Storage.Bucket{...}}

      iex> Supabase.Storage.retrieve_bucket_info(invalid_conn, "avatars")
      {:error, reason}

  """
  @impl true
  def retrieve_bucket_info(client, id) when is_client(client) do
    case Client.retrieve_connection(client) do
      nil ->
        {:error, :invalid_client}

      %Conn{access_token: token, api_key: api_key, base_url: base_url} ->
        BucketHandler.retrieve_info(base_url, api_key, token, id)
    end
  end

  @doc """
  Creates a new bucket in the current project given a map of attributes.

  ## Attributes

  * `id`: the id of the bucket to be created, required
  * `name`: the name of the bucket to be created, defaults to the `id` provided
  * `file_size_limit`: the maximum size of a file in bytes
  * `allowed_mime_types`: a list of allowed mime types, defaults to allow all MIME types
  * `public`: whether the bucket is public or not, defaults to `false`

  ## Notes

  * Policy permissions required
    * `buckets` permissions: `insert`
    * `objects` permissions: none

  ## Examples

      iex> Supabase.Storage.create_bucket(client, %{id: "avatars"})
      {:ok, %Supabase.Storage.Bucket{...}}

      iex> Supabase.Storage.create_bucket(invalid_conn, %{id: "avatars"})
      {:error, reason}

  """
  @impl true
  def create_bucket(client, attrs) when is_client(client) do
    with {:ok, bucket_params} <- Bucket.create_changeset(attrs),
         %Conn{access_token: token, api_key: api_key, base_url: base_url} <-
           Client.retrieve_connection(client),
         {:ok, _} <- BucketHandler.create(base_url, api_key, token, bucket_params) do
      retrieve_bucket_info(client, bucket_params.id)
    else
      nil ->
        {:error, :invalid_client}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Updates a bucket in the current project given a map of attributes.

  ## Attributes

  * `file_size_limit`: the maximum size of a file in bytes
  * `allowed_mime_types`: a list of allowed mime types, defaults to allow all MIME types
  * `public`: whether the bucket is public or not, defaults to `false`

  Isn't possible to update a bucket's `id` or `name`. If you want or need this, you should
  firstly delete the bucket and then create a new one.

  ## Notes

  * Policy permissions required
    * `buckets` permissions: `update`
    * `objects` permissions: none

  ## Examples

      iex> Supabase.Storage.update_bucket(client, bucket, %{public: true})
      {:ok, %Supabase.Storage.Bucket{...}}

      iex> Supabase.Storage.update_bucket(invalid_conn, bucket, %{public: true})
      {:error, reason}

  """
  @impl true
  def update_bucket(client, bucket, attrs) when is_client(client) do
    with {:ok, bucket_params} <- Bucket.update_changeset(bucket, attrs),
         %Conn{access_token: token, api_key: api_key, base_url: base_url} <-
           Client.retrieve_connection(client),
         {:ok, _} <- BucketHandler.update(base_url, api_key, token, bucket.id, bucket_params) do
      retrieve_bucket_info(client, bucket.id)
    else
      nil ->
        {:error, :invalid_client}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Empties a bucket in the current project. This action deletes all objects in the bucket.

  ## Notes

  * Policy permissions required
    * `buckets` permissions: `update`
    * `objects` permissions: `delete`

  ## Examples

      iex> Supabase.Storage.empty_bucket(client, bucket)
      {:ok, :emptied}

      iex> Supabase.Storage.empty_bucket(invalid_conn, bucket)
      {:error, reason}

  """
  @impl true
  def empty_bucket(client, %Bucket{} = bucket) when is_client(client) do
    case Client.retrieve_connection(client) do
      nil ->
        {:error, :invalid_client}

      %Conn{access_token: token, api_key: api_key, base_url: base_url} ->
        BucketHandler.empty(base_url, api_key, token, bucket.id)
    end
  end

  @doc """
  Deletes a bucket in the current project. Notice that this also deletes all objects in the bucket.

  ## Notes

  * Policy permissions required
    * `buckets` permissions: `delete`
    * `objects` permissions: `delete`

  ## Examples

      iex> Supabase.Storage.delete_bucket(client, bucket)
      {:ok, :deleted}

      iex> Supabase.Storage.delete_bucket(invalid_conn, bucket)
      {:error, reason}

  """
  @impl true
  def delete_bucket(client, %Bucket{} = bucket) when is_client(client) do
    with %Conn{access_token: token, api_key: api_key, base_url: base_url} <-
           Client.retrieve_connection(client),
         {:ok, _} <- BucketHandler.delete(base_url, api_key, token, bucket.id) do
      {:ok, :deleted}
    else
      nil ->
        {:error, :invalid_client}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Removes an object from a bucket in the current project.

  ## Notes

  * Policy permissions required
    * `buckets` permissions: none
    * `objects` permissions: `delete`

  ## Examples

      iex> Supabase.Storage.remove_object(client, bucket, object)
      {:ok, :deleted}

      iex> Supabase.Storage.remove_object(invalid_conn, bucket, object)
      {:error, reason}

  """
  @impl true
  def remove_object(client, %Bucket{} = bucket, %Object{} = object) when is_client(client) do
    case Client.retrieve_connection(client) do
      nil ->
        {:error, :invalid_client}

      %Conn{access_token: token, api_key: api_key, base_url: base_url} ->
        ObjectHandler.remove(base_url, api_key, token, bucket.name, object.path)
    end
  end

  @doc """
  Moves a object from a bucket and send it to another bucket, in the current project.
  Notice that isn't necessary to pass the current bucket, because the object already
  contains this information.

  ## Notes

  * Policy permissions required
    * `buckets` permissions: none
    * `objects` permissions: `delete` and `create`

  ## Examples

      iex> Supabase.Storage.move_object(client, bucket, object)
      {:ok, :moved}

      iex> Supabase.Storage.move_object(invalid_conn, bucket, object)
      {:error, reason}

  """
  @impl true
  def move_object(client, %Bucket{} = bucket, %Object{} = object, to) when is_client(client) do
    case Client.retrieve_connection(client) do
      nil ->
        {:error, :invalid_client}

      %Conn{access_token: token, api_key: api_key, base_url: base_url} ->
        ObjectHandler.move(base_url, api_key, token, bucket.name, object.path, to)
    end
  end

  @doc """
  Copies a object from a bucket and send it to another bucket, in the current project.
  Notice that isn't necessary to pass the current bucket, because the object already
  contains this information.

  ## Notes

  * Policy permissions required
    * `buckets` permissions: none
    * `objects` permissions: `create`

  ## Examples

      iex> Supabase.Storage.copy_object(client, bucket, object)
      {:ok, :copied}

      iex> Supabase.Storage.copy_object(invalid_conn, bucket, object)
      {:error, reason}

  """
  @impl true
  def copy_object(client, %Bucket{} = bucket, %Object{} = object, to) when is_client(client) do
    case Client.retrieve_connection(client) do
      nil ->
        {:error, :invalid_client}

      %Conn{access_token: token, api_key: api_key, base_url: base_url} ->
        ObjectHandler.copy(base_url, api_key, token, bucket.name, object.path, to)
    end
  end

  @doc """
  Retrieves information about an object in a bucket in the current project.

  ## Notes

  * Policy permissions required
    * `buckets` permissions: none
    * `objects` permissions: `select`

  ## Examples

      iex> Supabase.Storage.retrieve_object_info(client, bucket, "some.png")
      {:ok, %Supabase.Storage.Object{...}}

      iex> Supabase.Storage.retrieve_object_info(invalid_conn, bucket, "some.png")
      {:error, reason}

  """
  @impl true
  def retrieve_object_info(client, %Bucket{} = bucket, wildcard) when is_client(client) do
    case Client.retrieve_connection(client) do
      nil ->
        {:error, :invalid_client}

      %Conn{access_token: token, api_key: api_key, base_url: base_url} ->
        ObjectHandler.get_info(base_url, api_key, token, bucket.name, wildcard)
    end
  end

  @doc """
  Lists a set of objects in a bucket in the current project.

  ## Searching

  You can pass a prefix to filter the objects returned. For example, if you have the following
  objects in your bucket:

      .
      └── bucket/
          ├── avatars/
          │   └── some.png
          ├── other.png
          └── some.pdf

  And you want to list only the objects inside the `avatars` folder, you can do:

      iex> Supabase.Storage.list_objects(client, bucket, "avatars/")
      {:ok, [%Supabase.Storage.Object{...}]}

  Also you can pass some search options as a `Supabase.Storage.SearchOptions` struct. Available
  options are:

  * `limit`: the maximum number of objects to return
  * `offset`: the number of objects to skip
  * `sort_by`:
    * `column`: the column to sort by, defaults to `created_at`
    * `order`: the order to sort by, defaults to `desc`

  ## Notes

  * Policy permissions required
    * `buckets` permissions: none
    * `objects` permissions: `select`

  ## Examples

      iex> Supabase.Storage.list_objects(client, bucket)
      {:ok, [%Supabase.Storage.Object{...}, ...]}

      iex> Supabase.Storage.list_objects(invalid_conn, bucket)
      {:error, reason}

  """
  @impl true
  def list_objects(client, %Bucket{} = bucket, prefix \\ "", opts \\ %SearchOptions{})
      when is_client(client) do
    case Client.retrieve_connection(client) do
      nil ->
        {:error, :invalid_client}

      %Conn{access_token: token, api_key: api_key, base_url: base_url} ->
        ObjectHandler.list(base_url, api_key, token, bucket.name, prefix, opts)
    end
  end

  @doc """
  Uploads a file to a bucket in the current project. Notice that you only need to
  pass the path to the file you want to upload, as the file will be read in a stream way
  to be sent to the server.

  ## Options

  You can pass some options as a `Supabase.Storage.ObjectOptions` struct. Available
  options are:

  * `cache_control`: the cache control header value, defaults to `3600`
  * `content_type`: the content type header value, defaults to `text/plain;charset=UTF-8`
  * `upsert`: whether to overwrite the object if it already exists, defaults to `false`

  ## Notes

  * Policy permissions required
    * `buckets` permissions: none
    * `objects` permissions: `insert`

  ## Examples

      iex> Supabase.Storage.upload_object(client, bucket, "avatars/some.png", "path/to/file.png")
      {:ok, %Supabase.Storage.Object{...}}

      iex> Supabase.Storage.upload_object(invalid_conn, bucket, "avatars/some.png", "path/to/file.png")
      {:error, reason}

  """
  @impl true
  def upload_object(client, %Bucket{} = bucket, path, file, opts \\ %ObjectOptions{})
      when is_client(client) do
    case Client.retrieve_connection(client) do
      nil ->
        {:error, :invalid_client}

      %Conn{access_token: token, api_key: api_key, base_url: base_url} ->
        file = Path.expand(file)
        ObjectHandler.create_file(base_url, api_key, token, bucket.name, path, file, opts)
    end
  end

  @doc """
  Downloads an object from a bucket in the current project. That return a binary that
  represents the object content.

  ## Notes

  * Policy permissions required
    * `buckets` permissions: none
    * `objects` permissions: `select`

  ## Examples

       iex> Supabase.Storage.download_object(client, %Bucket{}, "avatars/some.png")
       {:ok, <<>>}

       iex> Supabase.Storage.download_object(invalid_conn, %Bucket{}, "avatars/some.png")
       {:error, reason}

  """
  @impl true
  def download_object(client, %Bucket{} = bucket, wildcard) when is_client(client) do
    case Client.retrieve_connection(client) do
      nil ->
        {:error, :invalid_client}

      %Conn{access_token: token, api_key: api_key, base_url: base_url} ->
        ObjectHandler.get(base_url, api_key, token, bucket.name, wildcard)
    end
  end

  @doc """
  Downloads an object from a bucket in the current project. That return a stream that
  represents the object content. Notice that the request to the server is only made
  when you start to consume the stream.

  ## Notes

  * Policy permissions required
    * `buckets` permissions: none
    * `objects` permissions: `select`

  ## Examples

       iex> Supabase.Storage.download_object_lazy(client, %Bucket{}, "avatars/some.png")
       {:ok, #Function<59.128620087/2 in Stream.resource/3>}

       iex> Supabase.Storage.download_object_lazy(invalid_conn, %Bucket{}, "avatars/some.png")
       {:error, reason}

  """
  @impl true
  def download_object_lazy(client, %Bucket{} = bucket, wildcard) when is_client(client) do
    case Client.retrieve_connection(client) do
      nil ->
        {:error, :invalid_client}

      %Conn{access_token: token, api_key: api_key, base_url: base_url} ->
        ObjectHandler.get_lazy(base_url, api_key, token, bucket.name, wildcard)
    end
  end

  @doc """
  Saves an object from a bucket in the current project to a file in the local filesystem.

  ## Notes

  * Policy permissions required
    * `buckets` permissions: none
    * `objects` permissions: `select`

  ## Examples

       iex> Supabase.Storage.save_object(client, "./some.png", %Bucket{}, "avatars/some.png")
       :ok

       iex> Supabase.Storage.save_object(client, "./some.png", %Bucket{}, "do_not_exist.png")
       {:error, reason}

  """
  @impl true
  def save_object(client, path, %Bucket{} = bucket, wildcard) when is_client(client) do
    with {:ok, bin} <- download_object(client, bucket, wildcard) do
      File.write(Path.expand(path), bin)
    end
  end

  @doc """
  Saves an object from a bucket in the current project to a file in the local filesystem.
  Notice that the request to the server is only made when you start to consume the stream.

  ## Notes

  * Policy permissions required
    * `buckets` permissions: none
    * `objects` permissions: `select`

  ## Examples

       iex> Supabase.Storage.save_object_stream(client, "./some.png", %Bucket{}, "avatars/some.png")
       :ok

       iex> Supabase.Storage.save_object_stream(client, "./some.png", %Bucket{}, "do_not_exist.png")
       {:error, reason}

  """
  @impl true
  def save_object_stream(client, path, %Bucket{} = bucket, wildcard) when is_client(client) do
    with {:ok, stream} <- download_object_lazy(client, bucket, wildcard) do
      fs = File.stream!(Path.expand(path))

      stream
      |> Stream.into(fs)
      |> Stream.run()
    end
  end

  @doc """
  Creates a signed URL for an object in a bucket in the current project. This URL can
  be used to perform an HTTP request to the object, without the need of authentication.
  Usually this is used to allow users to download objects from a bucket.

  ## Notes

  * Policy permissions required
    * `buckets` permissions: none
    * `objects` permissions: `select`

  ## Examples

       iex> Supabase.Storage.create_signed_url(client, bucket, "avatars/some.png", 3600)
       {:ok, "https://<project>.supabase.co"/object/sign/<bucket>/<file>?token=<token>}

       iex> Supabase.Storage.create_signed_url(invalid_client, bucket, "avatars/some.png", 3600)
       {:error, :invalid_client}

  """
  @impl true
  def create_signed_url(client, %Bucket{} = bucket, path, expires_in) when is_client(client) do
    with %Conn{access_token: token, api_key: api_key, base_url: base_url} <-
           Client.retrieve_connection(client),
         {:ok, sign_url} <-
           ObjectHandler.create_signed_url(
             base_url,
             api_key,
             token,
             bucket.name,
             path,
             expires_in
           ) do
      {:ok, URI.to_string(URI.merge(base_url, sign_url))}
    else
      nil ->
        {:error, :invalid_client}

      err ->
        err
    end
  end
end
