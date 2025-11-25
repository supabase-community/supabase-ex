import Config

if config_env() == :dev do
  config :supabase_potion, SupabasePotion.Client,
    base_url: System.fetch_env!("SUPABASE_URL"),
    api_key: System.fetch_env!("SUPABASE_KEY"),
    env: config_env()

  config :supabase_potion, json_library: JSON
end

if config_env() == :test do
  config :supabase_potion, json_library: Jason
end
