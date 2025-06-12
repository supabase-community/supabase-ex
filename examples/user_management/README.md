# Supabase Phoenix User Management

This example demonstrates how to build a user management application using Phoenix LiveView and Supabase. It's a Phoenix port of the [Nuxt 3 User Management example](https://github.com/supabase/supabase/tree/master/examples/user-management/nuxt3-user-management).

## Features

This example shows how to:

- Sign users in with Supabase Auth using [magic link](https://supabase.io/docs/reference/dart/auth-signin#sign-in-with-magic-link)
- Store and retrieve user profile data with [Supabase database](https://supabase.io/docs/guides/database)
- Upload and display avatar images using [Supabase storage](https://supabase.io/docs/guides/storage)
- Protect routes with Phoenix authentication

## Getting Started

Before running this app, you need to create a Supabase project and set up your environment variables.

1. Create a Supabase project
2. Copy your Supabase URL and API key from the project settings
3. Set environment variables:

```bash
export SUPABASE_URL=https://your-project.supabase.co
export SUPABASE_KEY=your-anon-key
```

4. Install dependencies and setup the database:

```bash
mix setup
```

5. Start the Phoenix server:

```bash
mix phx.server
```

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Database Schema

The example uses the following database schema for user profiles and storage:

```sql
-- Create a table for public "profiles"
create table profiles (
  id uuid primary key,
  user_id uuid not null,
  username text,
  website text,
  avatar_url text,
  inserted_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table profiles enable row level security;

create policy "Public profiles are viewable by everyone."
  on profiles for select
  using ( true );

create policy "Users can insert their own profile."
  on profiles for insert
  with check ( auth.uid() = user_id );

create policy "Users can update own profile."
  on profiles for update
  using ( auth.uid() = user_id );

-- Set up Storage
insert into storage.buckets (id, name)
values ('avatars', 'avatars');

create policy "Avatar images are publicly accessible."
  on storage.objects for select
  using ( bucket_id = 'avatars' );

create policy "Anyone can upload an avatar."
  on storage.objects for insert
  with check ( bucket_id = 'avatars' );
```

## Implementation Notes

This example uses:

- [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view) for interactive UI
- [Supabase Auth (GoTrue)](https://github.com/zoedsoupe/supabase-ex/tree/main/auth-ex) for authentication
- [Supabase Storage](https://github.com/zoedsoupe/supabase-ex/tree/main/storage-ex) for file uploads
- [Supabase Database](https://github.com/zoedsoupe/supabase-ex) for data access through Ecto

Authentication is implemented using magic links (email OTP) with the help of the `supabase.gen.auth` mix task from the `auth-ex` package.