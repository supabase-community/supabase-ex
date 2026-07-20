# Supabase Elixir

Supabase Community Elixir SDK

## Compatibility

We support the latest 3 stable Elixir versions.

<!-- x-release-please-start-version -->

```elixir
def deps do
  [
    {:supabase_potion, "~> 1.0.0"}, # base SDK
    {:supabase_storage, "~> 0.4"}, # storage integration
    {:supabase_auth, "~> 1.0.0"}, # auth integration
    {:supabase_postgrest, "~> 1.2.2"}, # postgrest integration
    {:supabase_functions, "~> 0.1.0"}, # edge functions integration
    {:supabase_realtime, "~> 0.5.0"}, # realtime integration
  ]
end
```

<!-- x-release-please-end -->

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

### HTTP Client Configuration

By default, `supabase_potion` starts a Finch pool named `Supabase.Finch`. You can customize this behavior with three application config keys:

#### `:http_client`

Replace the default Finch adapter with a custom HTTP client module:

```elixir
config :supabase_potion, http_client: MyApp.CustomHTTPClient
```

When set, no Finch pool is started automatically.

#### `:finch_name`

Use your own Finch instance instead of the default `Supabase.Finch`:

```elixir
config :supabase_potion, finch_name: MyApp.Finch
```

When set, no Finch pool is started automatically — you are responsible for starting the named Finch process.

#### `:finch_pool`

Customize the pool configuration for the default `Supabase.Finch` instance:

```elixir
config :supabase_potion, finch_pool: %{default: [size: 25, count: 4]}
```

Only takes effect when using the default Finch pool (i.e. neither `:http_client` nor `:finch_name` are set). Defaults to `%{default: [size: 10]}`.
