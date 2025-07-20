defmodule UserManagementWeb.Router do
  use UserManagementWeb, :router

  import UserManagementWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {UserManagementWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  ## Authentication routes
  scope "/", Elixir.UserManagementWeb do
    pipe_through [:browser, :require_authenticated_user]

    delete "/logout", SessionController, :delete
  end

  scope "/", Elixir.UserManagementWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :current_user,
      on_mount: [
        {UserManagementWeb.UserAuth, :mount_current_user},
        {UserManagementWeb.UserAuth, :redirect_if_user_is_authenticated}
      ] do
      live "/", LoginLive, :new
    end

    post "/", SessionController, :create
    post "/:token", SessionController, :token
  end
end
