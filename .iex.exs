key = System.get_env("SUPABASE_KEY")
url = System.get_env("SUPABASE_URL")

client = url && key && Supabase.init_client!(url, key)
