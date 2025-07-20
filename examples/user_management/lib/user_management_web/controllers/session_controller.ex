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
        |> redirect(to: ~p"/")
    end
  end

  def token(conn, %{} = params) do
    create(conn, %{"user" => params})
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserManagementWeb.UserAuth.log_out_user(:global)
  end

  def log_in_with_strategy(conn, %{"user" => %{"token_hash" => token, "type" => type}})
      when is_binary(token) do
    UserManagementWeb.UserAuth.verify_otp_and_log_in(conn, %{token_hash: token, type: type})
  end

  def log_in_with_strategy(conn, %{"user" => %{} = params}) do
    UserManagementWeb.UserAuth.log_in_user_with_otp(conn, params)
  end
end
