defmodule UserManagementWeb.LoginLive do
  use UserManagementWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div class="row flex flex-center">
      <div class="col-6">
        <.header>
          Supabase + Phoenix
          <:subtitle>
            Sign in via magic link with your email below
          </:subtitle>
        </.header>

        <.simple_form for={@form} id="login_form" phx-submit="send_magic_link" as={:user}>
          <.input field={@form[:email]} type="email" placeholder="Your email" required />
          <:actions>
            <.button class="block" phx-disable-with="Loading...">
              {if @loading, do: "Loading", else: "Send magic link"}
            </.button>
          </:actions>
        </.simple_form>

        <.flash_group flash={@flash} />
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    form = to_form(%{"email" => nil}, as: "user")
    {:ok, assign(socket, form: form, loading: false)}
  end

  @impl true
  def handle_event("send_magic_link", %{"user" => %{"email" => email}}, socket) do
    # Set loading state
    socket = assign(socket, loading: true)

    {:ok, client} = UserManagementWeb.UserAuth.get_client()

    case Supabase.GoTrue.sign_in_with_otp(client, %{email: email}) do
      {:ok, _result} ->
        {:noreply,
         socket
         |> assign(loading: false)
         |> put_flash(
           :info,
           "Magic link sent to #{email}. Check your inbox and follow the link to sign in."
         )}

      {:error, %Supabase.Error{metadata: metadata}} ->
        message = get_in(metadata, [:resp_body, "msg"]) || "Unknown error"

        {:noreply,
         socket
         |> assign(loading: false)
         |> put_flash(:error, "Couldn't send magic link: #{message}")}
    end
  end
end
