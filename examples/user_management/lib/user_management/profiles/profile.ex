defmodule UserManagement.Profiles.Profile do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "profiles" do
    field :username, :string
    field :website, :string
    field :avatar_url, :string

    timestamps(inserted_at: false)
  end

  @doc false
  def changeset(profile, attrs) do
    profile
    |> cast(attrs, [:user_id, :username, :website, :avatar_url])
    |> validate_required([:user_id])
    |> unique_constraint(:user_id)
    |> unique_constraint(:username)
    |> validate_format(:website, ~r/^https?:\/\//, message: "must start with http:// or https://")
  end

  @doc """
  Changeset for updating a profile.
  Only allows updating certain fields, not the user_id.
  """
  def update_changeset(profile, attrs) do
    profile
    |> cast(attrs, [:username, :website, :avatar_url])
    |> unique_constraint(:username)
    |> validate_format(:website, ~r/^https?:\/\//, message: "must start with http:// or https://")
  end
end
