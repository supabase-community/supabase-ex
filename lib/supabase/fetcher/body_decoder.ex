defmodule Supabase.Fetcher.BodyDecoder do
  @moduledoc """
  Behaviour to define custom body decoders to a HTTP response

  TO define a custom body decoder you need to implement this behaviour and
  register it into the request builder that will use it, for example, for a custom
  JSONDecoder:

      defmodule MyJSONDecoder do
        @behaviour Supabase.Fetcher.BodyDecoder

        @impl true
        def decode(%Finch.Response{} = resp, opts) do
        end
      end

  When registering custom body decoder, you can pass it custom options as keyword list
  so they'll be available as the second parameter of the `decode/2` behaviour function.
  """

  alias Supabase.Fetcher.Response

  @callback decode(Response.t(), options) :: {:ok, body :: term} | {:error, term}
            when options: keyword
end

defmodule Supabase.Fetcher.JSONDecoder do
  @moduledoc """
  The default body decoder to HTTP responses.

  Decoding rules:

  - Empty bodies (`nil` or `""`) decode to `nil`, so `204`/`HEAD`/empty `2xx`
    responses succeed.
  - Bodies with a non-JSON `content-type` pass through untouched.
  - JSON bodies that fail to decode return a `Supabase.Error` with the
    response metadata attached, instead of leaking the raw decode error.
  """

  alias Supabase.Error
  alias Supabase.Fetcher.Response

  @behaviour Supabase.Fetcher.BodyDecoder

  @doc "Tries to decode the response body as JSON"
  @impl true
  def decode(resp, _opts \\ [])

  def decode(%Response{body: body}, _) when body in [nil, ""], do: {:ok, nil}

  def decode(%Response{body: body} = resp, _) when is_binary(body) do
    content_type = Response.get_header(resp, "content-type")

    cond do
      is_binary(content_type) and not json_content_type?(content_type) ->
        {:ok, body}

      is_binary(content_type) ->
        do_decode(body, resp)

      true ->
        # no content-type: attempt JSON, fall back to the raw body
        case JSON.decode(body) do
          {:ok, decoded} -> {:ok, decoded}
          {:error, _} -> {:ok, body}
        end
    end
  end

  def decode(%Response{body: body}, _), do: {:ok, body}

  defp json_content_type?(content_type) do
    content_type
    |> String.downcase()
    |> String.contains?("json")
  end

  defp do_decode(body, resp) do
    case JSON.decode(body) do
      {:ok, decoded} ->
        {:ok, decoded}

      {:error, reason} ->
        {:error,
         Error.new(
           code: :invalid_json_body,
           service: nil,
           metadata: %{
             resp_status: resp.status,
             resp_body: body,
             raw_error: reason
           }
         )}
    end
  end
end
