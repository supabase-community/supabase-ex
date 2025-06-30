defmodule UserManagementWeb.Router do
  use UserManagementWeb, :router

  # Import authentication plugs
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
  scope "/", UserManagementWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :authenticated,
      on_mount: [
        {UserManagementWeb.UserAuth, :mount_current_user},
        {UserManagementWeb.UserAuth, :ensure_authenticated}
      ] do
      live "/profile", ProfileLive, :index
    end

    delete "/logout", SessionController, :delete
  end

  scope "/", UserManagementWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :non_authenticated,
      on_mount: [
        {UserManagementWeb.UserAuth, :mount_current_user},
        {UserManagementWeb.UserAuth, :redirect_if_user_is_authenticated}
      ] do
      live "/", LoginLive, :new
    end

    post "/", SessionController, :create
    post "/:token", SessionController, :token
    get "/sessions/token", SessionController, :token
  end
end
