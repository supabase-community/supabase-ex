defmodule Supabase.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_start_type, _args) do
    children =
      if start_default_finch?(),
        do: [{Finch, name: Supabase.Finch, pools: get_finch_pool()}],
        else: []

    opts = [strategy: :one_for_one, name: Supabase.Supervisor]

    Supervisor.start_link(children, opts)
  end

  defp start_default_finch? do
    is_nil(Application.get_env(:supabase_potion, :http_client)) and
      is_nil(Application.get_env(:supabase_potion, :finch_name))
  end

  defp get_finch_pool do
    Application.get_env(:supabase_potion, :finch_pool, %{default: [size: 10]})
  end
end
