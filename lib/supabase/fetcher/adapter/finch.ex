defmodule Supabase.Fetcher.Adapter.Finch do
  @moduledoc """
  HTTP client adapter for `Supabase.Fetcher` using Finch.

  By default uses the `Supabase.Finch` pool. To use your own Finch instance:

      config :supabase_potion, finch_name: MyApp.Finch
  """

  use Supabase.Fetcher.Adapter

  import Supabase.Fetcher.Request, only: [with_body: 2, with_headers: 2]

  # Matches Finch's own default receive timeout.
  @default_receive_timeout 15_000

  @impl true
  def request(%Request{method: method, headers: headers} = b, opts \\ []) do
    {name, opts} = Keyword.pop_lazy(opts, :name, fn -> finch_name() end)

    query = URI.encode_query(b.query)
    url = URI.append_query(b.url, query)

    method
    |> Finch.build(url, headers, b.body)
    |> Finch.request(name, opts)
  end

  @impl true
  def request_async(%Request{method: method, headers: headers} = b, opts \\ []) do
    {name, opts} = Keyword.pop_lazy(opts, :name, fn -> finch_name() end)
    {timeout, opts} = Keyword.pop(opts, :receive_timeout, @default_receive_timeout)

    query = URI.encode_query(b.query)
    url = URI.append_query(b.url, query)

    ref =
      method
      |> Finch.build(url, headers, b.body)
      |> then(&Finch.async_request(&1, name, opts))

    collect_async(ref, timeout, %Finch.Response{status: nil, headers: [], body: []})
  end

  defp collect_async(ref, timeout, acc) do
    receive do
      {^ref, {:status, status}} ->
        collect_async(ref, timeout, %{acc | status: status})

      {^ref, {:headers, headers}} ->
        collect_async(ref, timeout, %{acc | headers: headers})

      {^ref, {:data, chunk}} ->
        collect_async(ref, timeout, %{acc | body: [chunk | acc.body]})

      {^ref, :done} ->
        body = acc.body |> Enum.reverse() |> IO.iodata_to_binary()
        {:ok, %{acc | body: body}}

      {^ref, {:error, error}} ->
        {:error, error}
    after
      timeout -> {:error, %Mint.TransportError{reason: :timeout}}
    end
  end

  @impl true
  def stream(%Request{method: method, headers: headers} = b, on_response \\ nil, opts \\ []) do
    {timeout, opts} = Keyword.pop(opts, :receive_timeout, @default_receive_timeout)

    query = URI.encode_query(b.query)
    url = URI.append_query(b.url, query)
    req = Finch.build(method, url, headers, b.body)
    ref = make_ref()
    {pid, mref} = spawn_stream_task(req, ref, opts)

    with {:ok, status} <- await_stream_head(ref, pid, mref, :status, timeout),
         {:ok, headers} <- await_stream_head(ref, pid, mref, :headers, timeout) do
      stream =
        Stream.resource(
          fn -> {ref, pid, mref, timeout} end,
          &receive_stream/1,
          fn {_, pid, mref, _} -> shutdown_stream_task(pid, mref) end
        )

      handle_stream(status, headers, stream, on_response, b)
    else
      {:error, error} ->
        shutdown_stream_task(pid, mref)
        {:error, error}
    end
  end

  defp await_stream_head(ref, pid, mref, kind, timeout) do
    receive do
      {:chunk, {^kind, value}, ^ref} -> {:ok, value}
      {:stream_error, ^ref, error} -> {:error, error}
      {:DOWN, ^mref, :process, ^pid, reason} -> {:error, reason}
    after
      timeout -> {:error, %Mint.TransportError{reason: :timeout}}
    end
  end

  defp handle_stream(status, headers, stream, on_response, b) do
    if is_function(on_response, 1) do
      case on_response.({status, headers, stream}) do
        :ok ->
          :ok

        {:ok, body} ->
          {:ok, body}

        {:error, %Supabase.Error{} = err} ->
          {:error, err}

        unexpected ->
          {:error, Supabase.Error.new(service: b.service, metadata: %{raw_error: unexpected})}
      end
    else
      body = Enum.to_list(stream) |> IO.iodata_to_binary()
      {:ok, %Finch.Response{status: status, body: body, headers: headers}}
    end
  catch
    {:stream_error, error} -> {:error, error}
  end

  defp spawn_stream_task(%Finch.Request{} = req, ref, opts) do
    me = self()

    {name, opts} = Keyword.pop_lazy(opts, :name, fn -> finch_name() end)

    spawn_monitor(fn ->
      on_chunk = fn chunk, _acc -> send(me, {:chunk, chunk, ref}) end

      case Finch.stream(req, name, nil, on_chunk, opts) do
        {:ok, _} -> send(me, {:stream_done, ref})
        {:error, error, _acc} -> send(me, {:stream_error, ref, error})
      end
    end)
  end

  defp receive_stream({ref, pid, mref, timeout} = acc) do
    receive do
      {:chunk, {:data, data}, ^ref} -> {[data], acc}
      {:stream_done, ^ref} -> {:halt, acc}
      {:stream_error, ^ref, error} -> throw({:stream_error, error})
      {:DOWN, ^mref, :process, ^pid, reason} -> throw({:stream_error, reason})
    after
      timeout -> throw({:stream_error, %Mint.TransportError{reason: :timeout}})
    end
  end

  defp shutdown_stream_task(pid, mref) do
    Process.demonitor(mref, [:flush])
    if Process.alive?(pid), do: Process.exit(pid, :kill)
    :ok
  end

  @impl true
  def upload(%Request{} = b, file, opts \\ []) do
    body_stream = File.stream!(file, 2048)
    %File.Stat{size: content_length} = File.stat!(file)

    # Only use MIME.from_path if content-type is not already set
    content_type =
      case Supabase.Fetcher.Request.get_header(b, "content-type") do
        nil -> MIME.from_path(file)
        existing -> existing
      end

    content_headers = [
      {"content-length", to_string(content_length)},
      {"content-type", content_type}
    ]

    b
    |> with_body({:stream, body_stream})
    |> with_headers(content_headers)
    |> request(opts)
  end

  defp finch_name do
    Application.get_env(:supabase_potion, :finch_name, Supabase.Finch)
  end

  defimpl Supabase.Fetcher.ResponseAdapter, for: Finch.Response do
    def from(%Finch.Response{} = resp) do
      %Supabase.Fetcher.Response{status: resp.status, headers: resp.headers, body: resp.body}
    end
  end
end
