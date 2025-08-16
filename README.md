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

There are two ways to create a `Supabase.Client`:
1. one off clients
2. self managed clients

#### One off clients

One off clients are created and managed by your application. They are useful for quick interactions with the Supabase API.

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

You can also implement the `Supabase.Client.Behaviour` callbacks to centralize client initialisation logic.

#### Self managed clients

Self managed clients are created and managed by a separate process in your application. They are useful for long running applications that need to interact with the Supabase API.

If you don't have experience with processes or are new to Elixir, you should read the getting started section of the official Elixir documentation - specifically about processes, concurrency and distribution before proceeding.
- [Processes](https://hexdocs.pm/elixir/processes.html)
- [Agent getting started](https://hexdocs.pm/elixir/agents.html)
- [GenServer getting started](https://hexdocs.pm/elixir/genservers.html)
- [Supervision trees getting started](https://hexdocs.pm/elixir/supervisor-and-application.html)

To define a self managed client, create a module that will hold the client state and the client process as an [Agent](https://hexdocs.pm/elixir/Agent.html).

```elixir
defmodule MyApp.Supabase.Client do
  use Supabase.Client, otp_app: :my_app
end
```

For that to work, you will also need to configure the client in your application's configuration. This can be configured as a compile-time entry in `config.exs` or as a runtime entry in `runtime.exs`:

```elixir
import Config

# `:my_app` here is the same `otp_app` option you passed
config :my_app, MyApp.Supabase.Client,
  base_url: "https://<supabase-url>", # required
  api_key: "<supabase-api-key>", # required
  access_token: "<supabase-token>", # optional
   # additional options
  db: [schema: "another"],
  auth: [flow_type: :implicit, debug: true],
  global: [headers: %{"custom-header" => "custom-value"}]
```

Then you can start the client process in your application supervision tree, generally in a `application.ex` module:

```elixir
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      MyApp.Supabase.Client
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

To interact with the client process:

```elixir
iex> {:ok, client} = MyApp.Supabase.Client.get_client()
iex> Supabase.GoTrue.sign_in_with_password(client, email: "", password: "")
```
