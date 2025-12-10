defmodule Supabase.Client.Storage do
  @moduledoc """
  Storage service configuration schema for Supabase client.

  This module defines configuration options for the Storage service,
  enabling support for large file uploads and custom storage routing.

  ## Fields

  - `:use_new_hostname` - When `true`, transforms the storage URL to use
    the storage-specific subdomain (e.g., `project.supabase.co` becomes
    `project.storage.supabase.co`). This subdomain is optimized for large
    file uploads (>50GB) and provides better streaming performance.
    Defaults to `false` for backward compatibility. Only applies to official
    Supabase domains (`.supabase.co`, `.supabase.in`, `.supabase.red`).
    Custom domains are left untouched.

  ## Examples

      # Use default storage hostname (backward compatible)
      %Supabase.Client.Storage{use_new_hostname: false}

      # Use storage subdomain for large file uploads
      %Supabase.Client.Storage{use_new_hostname: true}

  """

  use Ecto.Schema
  import Ecto.Changeset

  @typedoc """
  Storage configuration struct.

  - `:use_new_hostname` - Enable storage subdomain transformation for large uploads
  """
  @type t :: %__MODULE__{
          use_new_hostname: boolean()
        }

  @typedoc """
  Storage configuration parameters.
  """
  @type params :: %{
          optional(:use_new_hostname) => boolean()
        }

  @primary_key false
  embedded_schema do
    field(:use_new_hostname, :boolean, default: false)
  end

  @doc """
  Creates a changeset for storage configuration.

  ## Parameters

    - `schema` - The storage config struct
    - `params` - Map or keyword list of configuration parameters

  ## Examples

      iex> changeset(%Supabase.Client.Storage{}, %{use_new_hostname: true})
      #Ecto.Changeset<...>

      iex> changeset(%Supabase.Client.Storage{}, [use_new_hostname: false])
      #Ecto.Changeset<...>

  """
  @spec changeset(t, map) :: Ecto.Changeset.t()
  def changeset(schema, params) do
    schema
    |> cast(params, [:use_new_hostname])
  end
end
