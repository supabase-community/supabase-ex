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
        },
        storage: %Supabase.Client.Storage{
          use_new_hostname: false
        }
      }
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Supabase.Client.Auth
  alias Supabase.Client.Db
  alias Supabase.Client.Global
  alias Supabase.Client.Storage

  @typedoc """
  The type of the `Supabase.Client` that will be returned from `Supabase.init_client/3`.

  ## Source
  https://supabase.com/docs/reference/javascript/initializing
  """
  @type t :: %__MODULE__{
          base_url: String.t(),
          access_token: String.t(),
          access_token_fn: access_token_fn | nil,
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
          auth: Auth.t(),
          storage: Storage.t()
        }

  @typedoc """
  A zero-arity function or `{module, function, args}` tuple that returns the
  access token to use as `Bearer` in requests. Invoked on every request, so
  short-lived tokens can be refreshed externally (e.g. by a GenServer).
  """
  @type access_token_fn :: (-> String.t()) | {module, atom, list}

  @typedoc """
  The type for the available additional options that can be passed
  to `Supabase.init_client/3` to configure the Supabase client.
  """
  @type options :: %{
          optional(:db) => Db.params(),
          optional(:global) => Global.params(),
          optional(:auth) => Auth.params(),
          optional(:storage) => Storage.params()
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
    field(:access_token_fn, :any, virtual: true)
    field(:base_url, :string)

    field(:realtime_url, :string)
    field(:auth_url, :string)
    field(:storage_url, :string)
    field(:functions_url, :string)
    field(:database_url, :string)

    embeds_one(:db, Db, defaults_to_struct: true, on_replace: :update)
    embeds_one(:global, Global, defaults_to_struct: true, on_replace: :update)
    embeds_one(:auth, Auth, defaults_to_struct: true, on_replace: :update)
    embeds_one(:storage, Storage, defaults_to_struct: true, on_replace: :update)
  end

  @spec changeset(attrs :: map) :: Ecto.Changeset.t()
  def changeset(%{base_url: base_url, api_key: api_key} = attrs) do
    {access_token_fn, attrs} = Map.pop(attrs, :access_token_fn)

    %__MODULE__{}
    |> cast(attrs, [:api_key, :base_url, :access_token])
    |> put_access_token_fn(access_token_fn)
    |> put_change(:access_token, attrs[:access_token] || api_key)
    |> cast_embed(:db, required: false)
    |> cast_embed(:global, required: false)
    |> cast_embed(:auth, required: false)
    |> cast_embed(:storage, required: false)
    |> validate_required([:base_url, :api_key])
    |> maybe_require_access_token()
    |> put_change(:auth_url, Path.join(base_url, "auth/v1"))
    |> put_change(:functions_url, Path.join(base_url, "functions/v1"))
    |> put_change(:database_url, Path.join(base_url, "rest/v1"))
    |> put_storage_url()
    |> put_change(:realtime_url, Path.join(base_url, "realtime/v1"))
  end

  defp put_access_token_fn(changeset, nil), do: changeset

  defp put_access_token_fn(changeset, fun) when is_function(fun, 0) do
    put_change(changeset, :access_token_fn, fun)
  end

  defp put_access_token_fn(changeset, {mod, fun, args})
       when is_atom(mod) and is_atom(fun) and is_list(args) do
    put_change(changeset, :access_token_fn, {mod, fun, args})
  end

  defp put_access_token_fn(changeset, other) do
    add_error(
      changeset,
      :access_token_fn,
      "must be a 0-arity function or an MFA tuple, got: #{inspect(other)}"
    )
  end

  defp maybe_require_access_token(changeset) do
    if get_field(changeset, :access_token_fn) do
      changeset
    else
      validate_required(changeset, [:access_token])
    end
  end

  @spec put_storage_url(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp put_storage_url(%Ecto.Changeset{} = changeset) do
    base_url = get_field(changeset, :base_url)

    if is_binary(base_url) and base_url != "" do
      default_storage_url = Path.join(base_url, "storage/v1")
      storage_url = Storage.Hostname.transform_storage_url(default_storage_url)

      put_change(changeset, :storage_url, storage_url)
    else
      changeset
    end
  end

  @doc """
  Helper function to swap the current acccess token being used in
  the Supabase client instance.
  """
  @spec update_access_token(t, String.t()) :: t
  def update_access_token(%__MODULE__{} = client, access_token) do
    %{client | access_token: access_token}
  end

  @doc """
  Resolves the access token to be used as `Bearer` in requests.

  When `access_token_fn` is set (a 0-arity function or MFA tuple), it is
  invoked on each call, otherwise the static `access_token` is returned.
  """
  @spec resolve_access_token(t) :: String.t() | nil
  def resolve_access_token(%__MODULE__{access_token_fn: nil, access_token: token}), do: token
  def resolve_access_token(%__MODULE__{access_token_fn: fun}) when is_function(fun, 0), do: fun.()

  def resolve_access_token(%__MODULE__{access_token_fn: {mod, fun, args}}),
    do: apply(mod, fun, args)

  @sb_new_format_prefixes ["sb_publishable_", "sb_secret_"]

  @doc """
  Returns true when the given key uses the new Supabase API key format
  (`sb_publishable_...` or `sb_secret_...`).

  New-format keys must be sent only in the `apikey` header, never as
  `Authorization: Bearer`, matching supabase-js 2.110.x behavior.
  """
  @spec new_format_key?(String.t() | nil) :: boolean
  def new_format_key?(key) when is_binary(key),
    do: String.starts_with?(key, @sb_new_format_prefixes)

  def new_format_key?(_), do: false

  @doc """
  Returns true when the given key starts with `sb_` but is not a recognized
  new-format key (`sb_publishable_` or `sb_secret_`).
  """
  @spec unrecognized_sb_key?(String.t() | nil) :: boolean
  def unrecognized_sb_key?(key) when is_binary(key),
    do: String.starts_with?(key, "sb_") and not new_format_key?(key)

  def unrecognized_sb_key?(_), do: false

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
