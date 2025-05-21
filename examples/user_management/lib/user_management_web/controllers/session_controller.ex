defmodule UserManagementWeb.SessionController do
  use UserManagementWeb, :controller

  def create(conn, %{"_action" => "confirmed"} = params) do
    create(conn, params, "User confirmed successfully.")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  defp create(conn, params, info) do
    with {:ok, conn} <- log_in_with_strategy(conn, params) do
      put_flash(conn, :info, info)
    else
      _ ->
        conn
        |> put_flash(:error, "Invalid credentials")
        |> redirect(to: ~p"/login")
    end
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
