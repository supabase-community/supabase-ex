defmodule UserManagementWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use UserManagementWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # The default endpoint for testing
      @endpoint UserManagementWeb.Endpoint

      use UserManagementWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import UserManagementWeb.ConnCase
    end
  end

  setup tags do
    UserManagement.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Setup helper that registers and logs in users.

      setup :register_and_log_in_user

  It stores an updated connection and a registered user in the
  test context.
  """
  def register_and_log_in_user(%{conn: conn}) do
    user = %Supabase.GoTrue.User{id: Ecto.UUID.generate(), email: "user@example.com"}
    session = %Supabase.GoTrue.Session{access_token: "123"}
    %{conn: log_in_user(conn, session), user: user, session: session}
  end

  def log_in_user(conn, session) do
    token = session.access_token

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:user_token, token)
    |> Plug.Conn.put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
    |> Phoenix.ConnTest.put_req_cookie("_user_management_web_user_remember_me", token)
    |> UserManagementWeb.UserAuth.fetch_current_user([])
  end
end
