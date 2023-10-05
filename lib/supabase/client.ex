defmodule Supabase.Client do
  @moduledoc """
  A client for interacting with Supabase. This module is responsible for
  managing the connection pool and the connection options.

  ## Usage

  Usually you don't need to use this module directly, instead you should
  use the `Supabase` module, available on `:supabase_potion` application.

  However, if you want to manage clients manually, you can leverage this
  module to start and stop clients dynamically. To start a single
  client manually, you need to add it to your supervision tree:

      defmodule MyApp.Application do
        use Application

        def start(_type, _args) do
          children = [
            {Supabase.Client, name: :supabase, client_info: %Supabase.Client{}}
          ]

          opts = [strategy: :one_for_one, name: MyApp.Supervisor]
          Supervisor.start_link(children, opts)
        end
      end

  Notice that starting a Client in this way, Client options will not be
  validated, so you need to make sure that the options are correct. Otherwise
  application will crash.

  ## Examples

      iex> Supabase.Client.start_link(name: :supabase, client_info: client_info)
      {:ok, #PID<0.123.0>}

      iex> Supabase.Client.retrieve_client(:supabase)
      %Supabase.Client{
        name: :supabase,
        conn: %{
          base_url: "https://<app-name>.supabase.io",
          api_key: "<supabase-api-key>",
          access_token: "<supabase-access-token>"
        },
        db: %Supabase.Client.Db{
          schema: "public"
        },
        global: %Supabase.Client.Global{
          headers: %{}
        },
        auth: %Supabase.Client.Auth{
          auto_refresh_token: true,
          debug: false,
          detect_session_in_url: true,
          flow_type: :implicit,
          persist_session: true,
          storage: nil,
          storage_key: "sb-<host>-auth-token"
        }
      }

      iex> Supabase.Client.retrieve_connection(:supabase)
      %Supabase.Client.Conn{
        base_url: "https://<app-name>.supabase.io",
        api_key: "<supabase-api-key>",
        access_token: "<supabase-access-token>"
      }
  """

  use Agent
  use Ecto.Schema

  import Ecto.Changeset

  alias Supabase.Client.Auth
  alias Supabase.Client.Conn
  alias Supabase.Client.Db
  alias Supabase.Client.Global

  alias Supabase.ClientRegistry

  defguard is_client(v) when is_atom(v) or is_pid(v)

  @type t :: %__MODULE__{
          name: atom,
          conn: Conn.t(),
          db: Db.t(),
          global: Global.t(),
          auth: Auth.t()
        }

  @type params :: %{
          name: atom,
          conn: Conn.params(),
          db: Db.params(),
          global: Global.params(),
          auth: Auth.params()
        }

  @primary_key false
  embedded_schema do
    field(:name, Supabase.Types.Atom)

    embeds_one(:conn, Conn)
    embeds_one(:db, Db)
    embeds_one(:global, Global)
    embeds_one(:auth, Auth)
  end

  @spec parse(params) :: {:ok, Supabase.Client.t()} | {:error, Ecto.Changeset.t()}
  def parse(attrs) do
    %__MODULE__{}
    |> cast(attrs, [:name])
    |> cast_embed(:conn, required: true)
    |> cast_embed(:db, required: false)
    |> cast_embed(:global, required: false)
    |> cast_embed(:auth, required: false)
    |> validate_required([:name])
    |> apply_action(:parse)
  end

  @spec parse!(params) :: Supabase.Client.t()
  def parse!(attrs) do
    case parse(attrs) do
      {:ok, changeset} ->
        changeset

      {:error, changeset} ->
        raise Ecto.InvalidChangesetError, changeset: changeset, action: :parse
    end
  end

  def start_link(config) do
    name = Keyword.get(config, :name)
    client_info = Keyword.get(config, :client_info)

    Agent.start_link(fn -> maybe_parse(client_info) end, name: name || __MODULE__)
  end

  defp maybe_parse(%__MODULE__{} = client), do: client
  defp maybe_parse(params), do: parse!(params)

  @spec retrieve_client(name) :: Supabase.Client.t() | nil
        when name: atom | pid
  def retrieve_client(name) when is_atom(name) do
    pid = ClientRegistry.lookup(name)
    pid && Agent.get(pid, & &1)
  end

  def retrieve_client(pid) when is_pid(pid), do: Agent.get(pid, & &1)

  @spec retrieve_connection(name) :: Conn.t() | nil
        when name: atom | pid
  def retrieve_connection(name) when is_atom(name) do
    pid = ClientRegistry.lookup(name)
    pid && Agent.get(pid, &Map.get(&1, :conn))
  end

  def retrieve_connection(pid) when is_pid(pid), do: Agent.get(pid, &Map.get(&1, :conn))
end
