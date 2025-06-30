defmodule UserManagement.Profiles do
  @moduledoc """
  The Profiles context.
  """

  import Ecto.Query, warn: false
  alias UserManagement.Repo
  alias UserManagement.Profiles.Profile

  @doc """
  Returns the list of profiles.
  """
  def list_profiles do
    Repo.all(Profile)
  end

  @doc """
  Gets a single profile by user_id.
  """
  def get_profile_by_user_id(user_id) do
    Repo.get_by(Profile, id: user_id)
  end

  @doc """
  Gets a single profile by username.
  """
  def get_profile_by_username(username) when is_binary(username) do
    Repo.get_by(Profile, username: username)
  end

  @doc """
  Gets a single profile.

  Raises `Ecto.NoResultsError` if the Profile does not exist.
  """
  def get_profile!(id), do: Repo.get!(Profile, id)

  @doc """
  Creates a profile.
  """
  def create_profile(attrs \\ %{}) do
    %Profile{}
    |> Profile.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a profile.
  """
  def update_profile(%Profile{} = profile, attrs) do
    profile
    |> Profile.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a profile.
  """
  def delete_profile(%Profile{} = profile) do
    Repo.delete(profile)
  end

  @doc """
  Creates or updates a profile for a user.
  """
  def upsert_profile(user_id, attrs) do
    case get_profile_by_user_id(user_id) do
      nil -> create_profile(Map.put(attrs, "user_id", user_id))
      profile -> update_profile(profile, attrs)
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking profile changes.
  """
  def change_profile(%Profile{} = profile, attrs \\ %{}) do
    Profile.changeset(profile, attrs)
  end
end
