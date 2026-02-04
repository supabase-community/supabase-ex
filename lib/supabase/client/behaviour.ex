defmodule Supabase.Client.Behaviour do
  @moduledoc """
  The behaviour for the Supabase Client. This behaviour defines a consistent
  API for modules that provide Supabase client functionality.

  ## Usage

  When you use the `Supabase.Client` macro in your module (similar to Ecto Repo),
  this behaviour is automatically implemented for you:

      defmodule MyApp.Supabase do
        use Supabase.Client, otp_app: :my_app
      end

  This provides two callbacks:

  - `get_client!/0` - Builds a fresh client struct from application config
  - `set_auth!/1` - Updates the access token on a client instance

  ## Custom Implementations

  You can also implement this behaviour manually if you need custom client
  initialization logic.
  """

  alias Supabase.Client

  @callback get_client! :: Client.t()
  @callback set_auth!(access_token :: String.t()) :: Client.t()
end
