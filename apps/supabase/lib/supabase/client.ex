defmodule Supabase.Client do
  @moduledoc false

  use Agent
  use Ecto.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{
          name: atom,
          connections: %{atom => atom},
          db: db,
          global: global,
          auth: auth
        }

  @type db :: %__MODULE__.Db{
          schema: String.t()
        }

  @type global :: %__MODULE__.Global{
          headers: Map.t()
        }

  @type auth :: %__MODULE__.Auth{
          auto_refresh_token: boolean(),
          debug: boolean(),
          detect_session_in_url: boolean(),
          flow_type: String.t(),
          persist_session: boolean(),
          storage: String.t(),
          storage_key: String.t()
        }

  @type params :: [
          name: atom,
          client_info: %{
            connections: %{atom => atom},
            db: %{
              schema: String.t()
            },
            global: %{
              headers: Map.t()
            },
            auth: %{
              auto_refresh_token: boolean(),
              debug: boolean(),
              detect_session_in_url: boolean(),
              flow_type: String.t(),
              persist_session: boolean(),
              storage: String.t(),
              storage_key: String.t()
            }
          }
        ]

  @primary_key false
  embedded_schema do
    field(:name, Supabase.Types.Atom)
    field(:connections, {:map, Supabase.Types.Atom})

    embeds_one :db, Db, primary_key: false do
      field(:schema, :string)
    end

    embeds_one :global, Global, primary_key: false do
      field(:headers, :map)
    end

    embeds_one :auth, Auth, primary_key: false do
      field(:auto_refresh_token, :boolean, default: true)
      field(:debug, :boolean, default: false)
      field(:detect_session_in_url, :boolean, default: true)
      field(:flow_type, :string)
      field(:persist_session, :boolean, default: true)
      field(:storage, :string)
      field(:storage_key, :string)
    end
  end

  @spec parse!(map) :: Supabase.Client.t()
  def parse!(attrs) do
    %__MODULE__{}
    |> cast(attrs, [:name])
    |> cast_embed(:db, required: true, with: &db_changeset/2)
    |> cast_embed(:global, required: true, with: &global_changeset/2)
    |> cast_embed(:auth, required: true, with: &auth_changeset/2)
    |> put_change(:connections, attrs[:connections] || %{})
    |> validate_required([:name, :connections])
    |> apply_action!(:parse)
  end

  defp db_changeset(schema, params) do
    schema
    |> cast(params, [:schema])
    |> validate_required([:schema])
  end

  defp global_changeset(schema, params) do
    cast(schema, params, [:headers])
  end

  defp auth_changeset(schema, params) do
    schema
    |> cast(
      params,
      ~w[auto_refresh_token debug detect_session_in_url persist_session flow_type storage storage_key]a
    )
    |> validate_required(
      ~w[auto_refresh_token debug detect_session_in_url persist_session flow_type]a
    )
  end

  def start_link(config) do
    name = Keyword.get(config, :name)
    client_info = Keyword.get(config, :client_info)

    Agent.start_link(fn -> parse!(client_info) end, name: name || __MODULE__)
  end

  @spec retrieve_client(pid) :: Supabase.Client.t()
  def retrieve_client(pid) do
    Agent.get(pid, & &1)
  end

  @spec retrieve_connections(pid) :: %{atom => atom}
  def retrieve_connections(pid) do
    Agent.get(pid, &Map.get(&1, :connections))
  end
end
