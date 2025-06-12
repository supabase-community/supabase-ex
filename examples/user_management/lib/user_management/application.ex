defmodule UserManagement.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      UserManagementWeb.Telemetry,
      UserManagement.Repo,
      {DNSCluster, query: Application.get_env(:user_management, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: UserManagement.PubSub},
      # Start a worker by calling: UserManagement.Worker.start_link(arg)
      # {UserManagement.Worker, arg},
      # Start to serve requests, typically the last entry
      UserManagementWeb.Endpoint,
      UserManagement.Supabase
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: UserManagement.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    UserManagementWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
