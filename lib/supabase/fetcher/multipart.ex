defmodule Supabase.Fetcher.Multipart do
  @moduledoc """
  Provides multipart/form-data encoding for file uploads and form submissions.

  Wraps the `multipart` library with a Supabase-friendly API.

  ## Part Types

  - `{:file, binary, opts}` - File from memory
  - `{:file_path, path, opts}` - File from disk (streaming)
  - `{:field, name, value}` - Text field
  - `{:field, name, value, opts}` - Text field with options

  ## Examples

      parts = [
        {:file_path, "/path/to/doc.pdf", name: "document"},
        {:field, "description", "Monthly report"}
      ]

      {content_type, body} = Supabase.Fetcher.Multipart.encode(parts)

  ## File Upload from Memory

      file_binary = File.read!("report.pdf")
      parts = [
        {:file, file_binary,
         name: "document",
         filename: "report.pdf",
         content_type: "application/pdf"}
      ]

      Supabase.Functions.invoke(client, "upload", body: {:multipart, parts})

  ## File Upload from Disk (Streaming)

      parts = [
        {:file_path, "/path/to/large-video.mp4", name: "video"}
      ]

      Supabase.Functions.invoke(client, "process-video", body: {:multipart, parts})

  ## Multiple Files with Metadata

      parts = [
        {:file_path, "/path/to/image1.jpg", name: "photos", filename: "photo1.jpg"},
        {:file_path, "/path/to/image2.jpg", name: "photos", filename: "photo2.jpg"},
        {:field, "album", "Vacation 2025"},
        {:field, "tags", "beach,sunset"}
      ]

      Supabase.Functions.invoke(client, "upload-album", body: {:multipart, parts})

  ## Phoenix/Plug Integration

      def upload_to_function(conn, _params) do
        %Plug.Upload{path: path, filename: filename, content_type: type} =
          conn.params["file"]

        parts = [
          {:file_path, path,
           name: "file",
           filename: filename,
           content_type: type},
          {:field, "user_id", conn.assigns.user_id}
        ]

        case Supabase.Functions.invoke(client, "process-upload",
               body: {:multipart, parts}) do
          {:ok, response} -> json(conn, response.body)
          {:error, error} -> put_status(conn, 500) |> json(%{error: error})
        end
      end

  ## Large File Streaming

      parts = [
        {:file_path, "/path/to/huge-file.zip", name: "backup"}
      ]

      # Use multipart_stream for very large files
      Supabase.Functions.invoke(client, "backup",
        body: {:multipart_stream, parts},
        timeout: 60_000  # 1 minute timeout
      )
  """

  @type part ::
          {:file, binary(), opts :: keyword()}
          | {:file_path, Path.t(), opts :: keyword()}
          | {:field, name :: String.t(), value :: String.t()}
          | {:field, name :: String.t(), value :: String.t(), opts :: keyword()}

  @type parts :: [part()]

  @doc """
  Encodes parts as multipart/form-data.

  Returns `{content_type, body}` where content_type includes the boundary.
  Body is returned as iodata for efficient memory usage.

  ## Options for file parts

  - `:name` (required) - Form field name
  - `:filename` - Custom filename (defaults to basename for file_path)
  - `:content_type` - Custom content-type (defaults to auto-detection)

  ## Options for field parts

  - `:content_type` - Custom content-type (defaults to none)

  ## Examples

      parts = [
        {:file, "PDF content", name: "doc", filename: "report.pdf"},
        {:field, "description", "Q4 Report"}
      ]

      {content_type, body} = Multipart.encode(parts)
      # => {"multipart/form-data; boundary=...", <<...>>}
  """
  @spec encode(parts()) :: {content_type :: String.t(), body :: iodata()}
  def encode(parts) when is_list(parts) do
    mp = Multipart.new()

    mp =
      Enum.reduce(parts, mp, fn part, acc ->
        Multipart.add_part(acc, encode_part(part))
      end)

    content_type = Multipart.content_type(mp, "multipart/form-data")
    body = Multipart.body_binary(mp)

    {content_type, body}
  end

  @doc """
  Encodes parts as streaming multipart/form-data.

  Returns `{content_type, stream}` where stream is an Enumerable.
  Useful for large file uploads to reduce memory usage.

  ## Examples

      parts = [{:file_path, "/large/file.zip", name: "backup"}]

      {content_type, stream} = Multipart.encode_stream(parts)

      # Stream can be consumed chunk by chunk
      Enum.each(stream, fn chunk ->
        # Process chunk
      end)
  """
  @spec encode_stream(parts()) :: {content_type :: String.t(), stream :: Enumerable.t()}
  def encode_stream(parts) when is_list(parts) do
    mp = Multipart.new()

    mp =
      Enum.reduce(parts, mp, fn part, acc ->
        Multipart.add_part(acc, encode_part(part))
      end)

    content_type = Multipart.content_type(mp, "multipart/form-data")
    stream = Multipart.body_stream(mp)

    {content_type, stream}
  end

  @doc """
  Calculates the total content length without loading files into memory.

  This is useful for setting the Content-Length header or for progress tracking.

  ## Examples

      parts = [
        {:file_path, "/path/to/file.pdf", name: "document"}
      ]

      length = Multipart.content_length(parts)
      # => 524288  (bytes)
  """
  @spec content_length(parts()) :: non_neg_integer()
  def content_length(parts) when is_list(parts) do
    mp = Multipart.new()

    mp =
      Enum.reduce(parts, mp, fn part, acc ->
        Multipart.add_part(acc, encode_part(part))
      end)

    Multipart.content_length(mp)
  end

  # Private: Convert our API to Multipart.Part API
  defp encode_part({:file, content, opts}) when is_binary(content) do
    name = Keyword.fetch!(opts, :name)
    filename = Keyword.get(opts, :filename, "file")
    content_type = Keyword.get(opts, :content_type, "application/octet-stream")

    # Use file_content_field for in-memory binary content
    Multipart.Part.file_content_field(
      filename,
      content,
      name,
      [],
      filename: filename,
      content_type: content_type
    )
  end

  defp encode_part({:file_path, path, opts}) do
    name = Keyword.fetch!(opts, :name)
    filename = Keyword.get(opts, :filename, Path.basename(path))

    # content_type: true means auto-detect via MIME
    content_type = Keyword.get(opts, :content_type, true)

    # Use file_field for streaming from disk
    Multipart.Part.file_field(path, name, [],
      filename: filename,
      content_type: content_type
    )
  end

  defp encode_part({:field, name, value}) when is_binary(name) and is_binary(value) do
    Multipart.Part.text_field(value, name)
  end

  defp encode_part({:field, name, value, opts}) when is_binary(name) and is_binary(value) do
    headers =
      case Keyword.get(opts, :content_type) do
        nil -> []
        content_type -> [{"content-type", content_type}]
      end

    Multipart.Part.text_field(value, name, headers)
  end

  defp encode_part(invalid) do
    raise ArgumentError, """
    Invalid multipart part: #{inspect(invalid)}

    Expected one of:
    - {:file, binary, opts} - File from memory (requires :name in opts)
    - {:file_path, path, opts} - File from disk (requires :name in opts)
    - {:field, name, value} - Text field
    - {:field, name, value, opts} - Text field with options
    """
  end
end
