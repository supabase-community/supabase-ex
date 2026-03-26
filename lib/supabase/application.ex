defmodule Supabase.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_start_type, _args) do
    children =
      if start_default_finch?() do
        [{Finch, name: Supabase.Finch, pools: %{default: [size: 10]}}]
      else
        []
      end
      |> maybe_append_child(fn e -> e == :dev end, SupabasePotion.Client)

    opts = [strategy: :one_for_one, name: Supabase.Supervisor]

    Supervisor.start_link(children, opts)
  end

  defp start_default_finch? do
    is_nil(Application.get_env(:supabase_potion, :http_client)) and
      is_nil(Application.get_env(:supabase_potion, :finch_name))
  end

  @spec maybe_append_child([child], (env -> boolean()), child) :: [child]
        when env: :dev | :prod | :test | nil, child: Supervisor.module_spec()
  defp maybe_append_child(children, pred, child) do
    env = get_env()

    cond do
      is_nil(env) -> children
      pred.(env) -> children ++ [child]
      not pred.(env) -> children
    end
  end

  @spec get_env :: :dev | :prod | :test | nil
  defp get_env, do: Application.get_env(:supabase_potion, :env)
end
