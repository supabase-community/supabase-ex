defmodule UserManagementWeb.RegistrationLive do
  use UserManagementWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">
        Register
        <:subtitle>
          Already have an account?
          <.link navigate={~p"/"} class="font-semibold text-brand hover:underline">
            Sign in
          </.link>
          to your account now.
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="registration_form"
        phx-submit="save"
        phx-change="validate"
        as={:user}
      >
        <.error :if={@check_errors}>
          Oops, something went wrong! Please check the errors below.
        </.error>

        <.input field={@form[:email]} type="email" label="Email" required />
        <.input field={@form[:password]} type="password" label="Password" required />

        <:actions>
          <.button phx-disable-with="Creating account..." class="w-full">
            Create an account
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(check_errors: false)
     |> assign_form()}
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    {:ok, client} = UserManagementWeb.UserAuth.get_client()
    %{"email" => email, "password" => password} = user_params

    case Supabase.GoTrue.sign_up(client, %{email: email, password: password}) do
      {:ok, _session} ->
        {:noreply,
         socket
         |> put_flash(:info, "User created successfully. Please sign in.")
         |> push_navigate(to: ~p"/")}

      {:error, %Supabase.Error{metadata: metadata}} ->
        message = get_in(metadata, [:resp_body, "msg"])

        {:noreply,
         socket
         |> put_flash(:error, "Registration failed: #{message}")
         |> assign(check_errors: true)
         |> assign_form()}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    {:noreply, assign_form(socket, user_params)}
  end

  defp assign_form(socket, user_params \\ %{}) do
    assign(socket, :form, to_form(user_params, as: "user"))
  end
end
