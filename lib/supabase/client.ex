defmodule Supabase.Client do
  @moduledoc """
  A client for interacting with Supabase. This module is responsible for
  managing the connection options for your Supabase project.

  ## Usage

  There are two ways to create a Supabase client:

  ### 1. Module-based Client (Recommended)

  Define a client module using the macro (similar to Ecto Repo). This approach
  reads configuration from your application config and builds a fresh client
  struct on each call:

      # lib/my_app/supabase.ex
      defmodule MyApp.Supabase do
        use Supabase.Client, otp_app: :my_app
      end

      # config/config.exs
      config :my_app, MyApp.Supabase,
        base_url: "https://<app-name>.supabase.io",
        api_key: "<supabase-api-key>",
        db: [schema: "public"],
        auth: [flow_type: :pkce]

      # Usage
      iex> client = MyApp.Supabase.get_client!()
      iex> %Supabase.Client{}

  ### 2. Direct Initialization

  Alternatively, create a client directly using `Supabase.init_client/3`:

      iex> base_url = "https://<app-name>.supabase.io"
      iex> api_key = "<supabase-api-key>"
      iex> Supabase.init_client(base_url, api_key, %{})
      {:ok, %Supabase.Client{}}

  For more information on how to configure your Supabase Client with additional
  options, please refer to the `Supabase.Client.t()` typespec.

  ## Client Structure

      %Supabase.Client{
        base_url: "https://<app-name>.supabase.io",
        api_key: "<supabase-api-key>",
        access_token: "<supabase-access-token>",
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
          storage_key: "sb-<host>-auth-token"
        }
      }
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Supabase.Client.Auth
  alias Supabase.Client.Db
  alias Supabase.Client.Global

  @typedoc """
  The type of the `Supabase.Client` that will be returned from `Supabase.init_client/3`.

  ## Source
  https://supabase.com/docs/reference/javascript/initializing
  """
  @type t :: %__MODULE__{
          base_url: String.t(),
          access_token: String.t(),
          api_key: String.t(),

          # helper fields
          realtime_url: String.t(),
          auth_url: String.t(),
          functions_url: String.t(),
          database_url: String.t(),
          storage_url: String.t(),

          # "public" options
          db: Db.t(),
          global: Global.t(),
          auth: Auth.t()
        }

  @typedoc """
  The type for the available additional options that can be passed
  to `Supabase.init_client/3` to configure the Supabase client.
  """
  @type options :: %{
          optional(:db) => Db.params(),
          optional(:global) => Global.params(),
          optional(:auth) => Auth.params()
        }

  @spec __using__(otp_app: atom) :: Macro.t()
  defmacro __using__(otp_app: otp_app) do
    quote do
      import Supabase.Client, only: [update_access_token: 2]

      alias Supabase.MissingSupabaseConfig

      @behaviour Supabase.Client.Behaviour

      @otp_app unquote(otp_app)

      @doc """
      Builds a `Supabase.Client` struct based on application config, so you can use it to interact with the Supabase API.

      Read more on `Supabase.Client.Behaviour`
      """
      @impl Supabase.Client.Behaviour
      def get_client! do
        config = Application.get_env(@otp_app, __MODULE__)
        base_url = Keyword.get(config, :base_url)
        api_key = Keyword.get(config, :api_key)
        Supabase.init_client!(base_url, api_key, Map.new(config))
      end

      @doc """
      This function updates the `access_token` field of client
      that will then be used by the integrations as the `Authorization`
      header in requests, by default the `access_token` have the same
      value as the `api_key`.

      Read more on `Supabase.Client.update_access_token/2`
      """
      @impl Supabase.Client.Behaviour
      def set_auth!(token) when is_binary(token) do
        update_access_token(get_client!(), token)
      end
    end
  end

  @primary_key false
  embedded_schema do
    field(:api_key, :string)
    field(:access_token, :string)
    field(:base_url, :string)

    field(:realtime_url, :string)
    field(:auth_url, :string)
    field(:storage_url, :string)
    field(:functions_url, :string)
    field(:database_url, :string)

    embeds_one(:db, Db, defaults_to_struct: true, on_replace: :update)
    embeds_one(:global, Global, defaults_to_struct: true, on_replace: :update)
    embeds_one(:auth, Auth, defaults_to_struct: true, on_replace: :update)
  end

  @spec changeset(attrs :: map) :: Ecto.Changeset.t()
  def changeset(%{base_url: base_url, api_key: api_key} = attrs) do
    %__MODULE__{}
    |> cast(attrs, [:api_key, :base_url, :access_token])
    |> put_change(:access_token, attrs[:access_token] || api_key)
    |> cast_embed(:db, required: false)
    |> cast_embed(:global, required: false)
    |> cast_embed(:auth, required: false)
    |> validate_required([:access_token, :base_url, :api_key])
    |> put_change(:auth_url, Path.join(base_url, "auth/v1"))
    |> put_change(:functions_url, Path.join(base_url, "functions/v1"))
    |> put_change(:database_url, Path.join(base_url, "rest/v1"))
    |> put_change(:storage_url, Path.join(base_url, "storage/v1"))
    |> put_change(:realtime_url, Path.join(base_url, "realtime/v1"))
  end

  @doc """
  Helper function to swap the current acccess token being used in
  the Supabase client instance.
  """
  @spec update_access_token(t, String.t()) :: t
  def update_access_token(%__MODULE__{} = client, access_token) do
    %{client | access_token: access_token}
  end

  defimpl Inspect, for: Supabase.Client do
    import Inspect.Algebra

    def inspect(%Supabase.Client{} = client, opts) do
      concat([
        "#Supabase.Client<",
        nest(
          concat([
            line(),
            "base_url: ",
            to_doc(client.base_url, opts),
            ",",
            line(),
            "schema: ",
            to_doc(client.db.schema, opts),
            ",",
            line(),
            "auth: (",
            "flow_type: ",
            to_doc(client.auth.flow_type, opts),
            ", ",
            "persist_session: ",
            to_doc(client.auth.persist_session, opts),
            ")"
          ]),
          2
        ),
        line(),
        ">"
      ])
    end
  end
end
