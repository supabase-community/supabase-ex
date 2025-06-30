defmodule UserManagementWeb.SessionController do
  use UserManagementWeb, :controller

  alias UserManagement.Profiles
  alias UserManagementWeb.UserAuth

  def create(conn, %{"_action" => "confirmed"} = params) do
    create(conn, params, "User confirmed successfully.")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  def token(conn, %{"token_hash" => _} = params) do
    create(conn, %{"user" => params})
  end

  defp create(conn, %{"user" => %{"token_hash" => token}}, info) when is_binary(token) do
    params = %{token_hash: token, type: :magiclink}

    with {:ok, conn} <- UserAuth.verify_otp_and_log_in(conn, params) do
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
    dbg(conn.assigns)

    if user = conn.assigns[:current_user] do
      case Profiles.get_profile_by_user_id(user.id) do
        nil ->
          email = user.email || "user-#{user.id}"
          username = make_username(email)
          params = %{"id" => user.id, "username" => username}

          UserManagement.Profiles.create_profile(params)

        _profile ->
          :ok
      end
    end
  end

  defp make_username(email) do
    email |> String.split("@") |> hd() |> String.replace(~r/[^a-zA-Z0-9]/, "")
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserManagementWeb.UserAuth.log_out_user(:global)
  end
end
