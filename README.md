# Supabase Elixir

Supabase Community Elixir SDK

```elixir
def deps do
  [
    {:supabase_potion, "~> 0.6"}, # base SDK
    {:supabase_storage, "~> 0.4"}, # storage integration
    {:supabase_auth, "~> 0.6"}, # auth integration
    {:supabase_postgrest, "~> 1.0"}, # postgrest integration
    {:supabase_functions, "~> 0.1"}, # edge functions integration
    {:supabase_realtime, "~> 0.1"}, # realtime integration
  ]
end
```

Individual product client documentation:

- [PostgREST](https://github.com/supabase-community/postgrest-ex)
- [Storage](https://github.com/supabase-community/storage-ex)
- [Auth](https://github.com/supabase-community/auth-ex)
- [Functions](https://github.com/supabase-community/functions-ex)
- [Realtime](https://github.com/supabase-community/realtime-ex)

### Clients

A `Supabase.Client` holds general information about Supabase that can be used to interact with any of the children integrations, for example: `Supabase.Storage` or `Supabase.UI`.

### Usage

#### Module-based Client (Recommended)

You can define a client module using the macro (similar to Ecto Repo). This approach reads configuration from your application config and builds a fresh client struct on each call:

```elixir
# lib/my_app/supabase.ex
defmodule MyApp.Supabase do
  use Supabase.Client, otp_app: :my_app
end

# config/config.exs
config :my_app, MyApp.Supabase,
  base_url: "https://<supabase-url>",
  api_key: "<supabase-api-key>",
  db: [schema: "public"],
  auth: [flow_type: :pkce],
  global: [headers: %{"custom-header" => "custom-value"}]

# Usage
iex> client = MyApp.Supabase.get_client!()
iex> %Supabase.Client{}
```

#### Direct Initialization

Alternatively, you can create a client directly using `Supabase.init_client/3`:

```elixir
iex> Supabase.init_client("https://<supabase-url>", "<supabase-api-key>")
iex> {:ok, %Supabase.Client{}}
```

Any additional config can be passed as the third argument as an [Enumerable](https://hexdocs.pm/elixir/Enumerable.html):

```elixir
iex> Supabase.init_client("https://<supabase-url>", "<supabase-api-key>",
  db: [schema: "another"],
  auth: [flow_type: :pkce],
  global: [headers: %{"custom-header" => "custom-value"}]
)
iex> {:ok, %Supabase.Client{}}
```

Initialized clients are Elixir structs without any managed state.
