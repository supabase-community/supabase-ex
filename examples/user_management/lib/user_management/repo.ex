defmodule UserManagement.Repo do
  use Ecto.Repo,
    otp_app: :user_management,
    adapter: Ecto.Adapters.Postgres
end
