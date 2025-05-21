-- Seed data for Supabase Local Development
-- This file will be executed when running `supabase start`

-- Create a table for public "profiles"
create table profiles (
  id uuid references auth.users not null,
  updated_at timestamp with time zone,
  username text unique,
  avatar_url text,
  website text,

  primary key (id),
  unique(username),
  constraint username_length check (char_length(username) >= 3)
);

alter table profiles enable row level security;

create policy "Public profiles are viewable by everyone."
  on profiles for select
  using ( true );

create policy "Users can insert their own profile."
  on profiles for insert
  with check ( (select auth.uid()) = id );

create policy "Users can update own profile."
  on profiles for update
  using ( (select auth.uid()) = id );

-- Set up Storage!
insert into storage.buckets (id, name)
values ('avatars', 'avatars');

create policy "Avatar images are publicly accessible."
  on storage.objects for select
  using ( bucket_id = 'avatars' );

create policy "Anyone can upload an avatar."
  on storage.objects for insert
  with check ( bucket_id = 'avatars' );

-- Create test users first (for local development only)
INSERT INTO auth.users (id, email, confirmation_sent_at)
VALUES 
  ('00000000-0000-0000-0000-000000000001', 'test1@example.com', NOW()),
  ('00000000-0000-0000-0000-000000000002', 'test2@example.com', NOW()),
  ('00000000-0000-0000-0000-000000000003', 'test3@example.com', NOW())
ON CONFLICT (id) DO NOTHING;

-- Note: The avatars storage bucket is created in the migrations
-- This is just a reminder that you can use the following path pattern for user avatars:
-- Storage path example: 'avatars/{user_id}.png'
