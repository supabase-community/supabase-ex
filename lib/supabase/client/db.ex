defmodule Supabase.Client.Db do
  @moduledoc """
  DB configuration schema. This schema is used to configure the database
  options. This schema is embedded in the `Supabase.Client` schema.

  ## Fields

  - `:schema` - The default schema to use. Defaults to `"public"`.
  - `:timeout` - Per-request timeout in milliseconds, forwarded as
    `receive_timeout` to the HTTP adapter. Defaults to `nil` (adapter default).

  For more information about the database options, see the documentation for
  the [client](https://supabase.com/docs/reference/javascript/initializing) and
  [database guides](https://supabase.com/docs/guides/database).
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          schema: String.t(),
          timeout: pos_integer | nil
        }
  @type params :: %{
          optional(:schema) => String.t(),
          optional(:timeout) => pos_integer | nil
        }

  @primary_key false
  embedded_schema do
    field(:schema, :string, default: "public")
    field(:timeout, :integer)
  end

  def changeset(schema, params) do
    schema
    |> cast(params, [:schema, :timeout])
    |> validate_number(:timeout, greater_than: 0)
  end
end
