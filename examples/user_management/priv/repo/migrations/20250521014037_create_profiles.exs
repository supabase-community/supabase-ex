defmodule UserManagement.Repo.Migrations.CreateProfiles do
  use Ecto.Migration

  def change do
    # Create the profiles table
    create table(:profiles, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :user_id, :uuid, null: false
      add :username, :string
      add :website, :string
      add :avatar_url, :string

      timestamps()
    end

    create unique_index(:profiles, [:user_id])
    create unique_index(:profiles, [:username])

    # Add Row Level Security (RLS) policies
    execute "ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;", ""

    # Policy for public profiles (read-only)
    execute """
    CREATE POLICY "Public profiles are viewable by everyone."
    ON profiles FOR SELECT
    USING (true);
    """, ""

    # Policy for users to update their own profile
    execute """
    CREATE POLICY "Users can update their own profile."
    ON profiles FOR UPDATE
    USING (auth.uid() = user_id);
    """, ""

    # Policy for users to insert their own profile
    execute """
    CREATE POLICY "Users can insert their own profile."
    ON profiles FOR INSERT
    WITH CHECK (auth.uid() = user_id);
    """, ""
  end
end
