defmodule UserManagement.Repo.Migrations.CreateStorageBuckets do
  use Ecto.Migration

  def change do
    # Create storage bucket for avatars
    execute """
    INSERT INTO storage.buckets (id, name, public)
    VALUES ('avatars', 'avatars', true);
    """, ""

    # Set up RLS policies for the avatars bucket
    execute """
    CREATE POLICY "Avatar images are publicly accessible."
    ON storage.objects FOR SELECT
    USING (bucket_id = 'avatars');
    """, ""

    execute """
    CREATE POLICY "Anyone can upload an avatar."
    ON storage.objects FOR INSERT
    WITH CHECK (bucket_id = 'avatars');
    """, ""

    execute """
    CREATE POLICY "Users can update their own avatars."
    ON storage.objects FOR UPDATE
    USING (bucket_id = 'avatars' AND owner = auth.uid());
    """, ""

    execute """
    CREATE POLICY "Users can delete their own avatars."
    ON storage.objects FOR DELETE
    USING (bucket_id = 'avatars' AND owner = auth.uid());
    """, ""
  end
end
