defmodule UserManagementWeb.LoginLive do
  use UserManagementWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm space-y-4">
      <.header class="text-center">
        <p>Log in</p>
        <:subtitle>
          Don't have an account?
          <.link navigate={~p"/register"} class="font-semibold text-brand hover:underline">
            Sign up
          </.link>
          for an account now.
        </:subtitle>
      </.header>

      <.login_form :for={s <- ["otp"]} strategy={s} form={@form} />
    </div>
    """
  end

  def login_form(%{strategy: "password"} = assigns) do
    ~H"""
    <.form :let={f} for={@form} id="login_form_password" action={~p"/login"} as={:user}>
      <.input field={f[:email]} type="email" label="Email" autocomplete="username" required />
      <.input
        field={f[:password]}
        type="password"
        label="Password"
        autocomplete="current-password"
        required
      />
      <.input field={f[:remember_me]} type="checkbox" label="Keep me logged in" />
      <.button class="w-full">
        Log in with password <span aria-hidden="true">→</span>
      </.button>
    </.form>
    """
  end

  def login_form(%{strategy: "otp"} = assigns) do
    ~H"""
    <.form :let={f} for={@form} id="login_form_otp" action={~p"/login"} as={:user}>
      <.input field={f[:email]} type="email" label="Email" required />
      <.button class="w-full">
        Send one-time password <span aria-hidden="true">→</span>
      </.button>
    </.form>
    """
  end

  def login_form(%{strategy: "oauth"} = assigns) do
    ~H"""
    <div class="space-y-4">
      <p class="text-center">Log in with a provider</p>
      <div class="flex justify-center space-x-4">
        <.button
          :for={provider <- ["github", "google", "facebook"]}
          class="w-full"
          phx-click="oauth_login"
          phx-value-provider={provider}
        >
          {provider}
        </.button>
      </div>
    </div>
    """
  end

  def login_form(%{strategy: "anon"} = assigns) do
    ~H"""
    <.form for={%{}} id="login_form_anon" action={~p"/login"} as={:user}>
      <.button class="w-full">
        Continue anonymously <span aria-hidden="true">→</span>
      </.button>
    </.form>
    """
  end

  def login_form(%{strategy: _} = assigns) do
    ~H"""
    <p>Strategy not implemented in LiveView yet</p>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    form = to_form(%{"email" => nil}, as: "user")
    {:ok, assign(socket, form: form)}
  end

  @impl true
  def handle_event("oauth_login", %{"provider" => provider}, socket) do
    # This would be handled by the controller
    {:noreply, push_navigate(socket, to: ~p"/login?provider=#{provider}")}
  end
end
