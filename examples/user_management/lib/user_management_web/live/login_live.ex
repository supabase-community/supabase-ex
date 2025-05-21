defmodule UserManagementWeb.LoginLive do
  use UserManagementWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm space-y-4">
      <.header class="text-center">
        <p>Sign in</p>
        <:subtitle>
          Sign in via magic link with your email below
        </:subtitle>
      </.header>

      <.simple_form for={@form} id="login_form" phx-submit="send_magic_link" as={:user}>
        <.input field={@form[:email]} type="email" label="Email" required />
        <:actions>
          <.button class="w-full" phx-disable-with="Sending...">
            Send magic link <span aria-hidden="true">→</span>
          </.button>
        </:actions>
      </.simple_form>

      <.flash_group flash={@flash} />
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    form = to_form(%{"email" => nil}, as: "user")
    {:ok, assign(socket, form: form, flash: %{})}
  end

  @impl true
  def handle_event("send_magic_link", %{"user" => %{"email" => email}}, socket) do
    {:ok, client} = UserManagementWeb.UserAuth.get_client()

    case Supabase.GoTrue.sign_in_with_otp(client, %{email: email}) do
      {:ok, _result} ->
        {:noreply,
         socket
         |> put_flash(
           :info,
           "Magic link sent to #{email}. Check your inbox and follow the link to sign in."
         )}

      {:error, %Supabase.Error{metadata: metadata}} ->
        message = get_in(metadata, [:resp_body, "msg"]) || "Unknown error"

        {:noreply,
         socket
         |> put_flash(:error, "Couldn't send magic link: #{message}")}
    end
  end
end
