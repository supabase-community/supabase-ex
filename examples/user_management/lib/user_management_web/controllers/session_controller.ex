defmodule UserManagementWeb.SessionController do
  use UserManagementWeb, :controller

  alias UserManagement.Profiles

  def create(conn, %{"_action" => "confirmed"} = params) do
    create(conn, params, "User confirmed successfully.")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  defp create(conn, params, info) do
    with {:ok, conn} <- log_in_with_strategy(conn, params) do
      conn
      |> maybe_create_profile()
      |> put_flash(:info, info)
    else
      _ ->
        conn
        |> put_flash(:error, "Invalid credentials")
        |> redirect(to: ~p"/")
    end
  end

  defp maybe_create_profile(conn) do
    if user = conn.assigns[:current_user] do
      case Profiles.get_profile_by_user_id(user.id) do
        nil ->
          email = user.email || "user-#{user.id}"
          username = make_username(email)

          UserManagement.Profiles.create_profile(%{
            "user_id" => user.id,
            "username" => username
          })

        _profile ->
          :ok
      end
    end
  end

  defp make_username(email) do
    email |> String.split("@") |> hd() |> String.replace(~r/[^a-zA-Z0-9]/, "")
  end

  def token(conn, %{"token" => token} = params) do
    create(conn, Map.put(params, "token", token))
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserManagementWeb.UserAuth.log_out_user(:global)
  end

  def log_in_with_strategy(conn, %{"user" => %{"token" => token}})
      when is_binary(token) do
    UserManagementWeb.UserAuth.log_in_user_with_otp(conn, %{"token" => token})
  end
end
