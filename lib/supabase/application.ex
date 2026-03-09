defmodule Supabase.Application do
  @moduledoc false

  use Application

  @finch_opts [name: Supabase.Finch, pools: %{:default => [size: 10]}]

  @impl true
  def start(_start_type, _args) do
    children = [{Finch, @finch_opts}]
    opts = [strategy: :one_for_one, name: Supabase.Supervisor]

    Supervisor.start_link(children, opts)
  end
end
