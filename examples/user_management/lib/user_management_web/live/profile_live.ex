defmodule UserManagementWeb.ProfileLive do
  use UserManagementWeb, :live_view

  alias UserManagement.Profiles
  alias UserManagement.Profiles.Profile

  @impl true
  def mount(_params, _session, socket) do
    if user = socket.assigns.current_user do
      profile =
        case Profiles.get_profile_by_user_id(user.id) do
          nil ->
            # Create profile if it doesn't exist yet
            email = user.email || "user-#{user.id}"
            username = email |> String.split("@") |> hd() |> String.replace(~r/[^a-zA-Z0-9]/, "")

            {:ok, profile} =
              Profiles.create_profile(%{
                "user_id" => user.id,
                "username" => username
              })

            profile

          profile ->
            profile
        end

      changeset = Profiles.change_profile(profile)

      {:ok,
       socket
       |> assign(:profile, profile)
       |> assign(:form, to_form(changeset))
       |> assign(:page_title, "Profile")
       |> assign(:avatar_url, profile.avatar_url)
       |> allow_upload(:avatar, 
          accept: ~w(.jpg .jpeg .png), 
          max_entries: 1,
          max_file_size: 5_000_000)}
    else
      {:ok, socket}
    end
  end

  @impl true
  def handle_event("save", %{"profile" => params}, socket) do
    case Profiles.update_profile(socket.assigns.profile, params) do
      {:ok, profile} ->
        {:noreply,
         socket
         |> put_flash(:info, "Profile updated successfully")
         |> assign(:profile, profile)
         |> assign(:form, to_form(Profiles.change_profile(profile)))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("validate", %{"profile" => params}, socket) do
    changeset =
      socket.assigns.profile
      |> Profiles.change_profile(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :avatar, ref)}
  end

  @impl true
  def handle_event("upload-avatar", _params, socket) do
    # Upload avatar to Supabase storage
    {:ok, client} = UserManagement.Supabase.get_client()

    uploaded_files =
      consume_uploaded_entries(socket, :avatar, fn %{path: path}, entry ->
        file_name = "#{socket.assigns.current_user.id}-#{entry.client_name}"
        file_type = entry.client_type
        
        # Upload file to Supabase storage in the avatars bucket
        file = File.read!(path)
        
        case Supabase.Storage.from(client, "avatars")
             |> Supabase.Storage.upload(file_name, file, content_type: file_type) do
          {:ok, data} ->
            file_path = "avatars/#{file_name}"
            
            # Get public URL
            {:ok, %{"publicUrl" => public_url}} = 
              Supabase.Storage.from(client, "avatars")
              |> Supabase.Storage.get_public_url(file_name)
              
            # Update profile with avatar URL
            {:ok, _profile} = 
              Profiles.update_profile(socket.assigns.profile, %{"avatar_url" => public_url})
              
            {:ok, public_url}
            
          {:error, error} ->
            {:error, error}
        end
      end)

    case uploaded_files do
      [url] ->
        {:noreply, 
         socket 
         |> assign(:avatar_url, url)
         |> put_flash(:info, "Avatar updated successfully")}
        
      _ ->
        {:noreply, 
         socket
         |> put_flash(:error, "Failed to upload avatar")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm space-y-10">
      <.header class="text-center">
        User Profile
        <:subtitle>
          Manage your profile information
        </:subtitle>
      </.header>

      <.simple_form for={@form} id="profile-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:username]} type="text" label="Username" required />
        <.input field={@form[:website]} type="url" label="Website" placeholder="https://example.com" />
        
        <div class="mt-4 mb-6">
          <label class="block text-sm font-semibold leading-6 text-zinc-800">Avatar</label>
          <div class="mt-2 flex items-center gap-4">
            <img 
              :if={@avatar_url} 
              src={@avatar_url} 
              alt="Avatar"
              class="h-16 w-16 rounded-full object-cover"
            />
            <img 
              :if={!@avatar_url} 
              src="/images/placeholder-avatar.png" 
              alt="Default Avatar"
              class="h-16 w-16 rounded-full object-cover"
            />
            
            <div class="flex-1">
              <.live_file_input upload={@uploads.avatar} class="hidden" id="avatar-input" />
              <div class="flex space-x-2">
                <button 
                  type="button" 
                  phx-click={JS.dispatch("click", to: "#avatar-input")}
                  class="rounded-lg bg-zinc-200 px-3 py-2 text-sm font-semibold leading-6 text-zinc-900 hover:bg-zinc-300"
                >
                  Choose File
                </button>
                <button
                  :if={Enum.any?(@uploads.avatar.entries)}
                  type="button"
                  phx-click="upload-avatar"
                  class="rounded-lg bg-brand px-3 py-2 text-sm font-semibold leading-6 text-white hover:bg-brand/90"
                >
                  Upload
                </button>
              </div>
              
              <div :if={Enum.any?(@uploads.avatar.entries)} class="mt-2">
                <%= for entry <- @uploads.avatar.entries do %>
                  <div class="flex items-center space-x-2">
                    <div class="text-sm"><%= entry.client_name %></div>
                    <button
                      type="button"
                      phx-click="cancel-upload"
                      phx-value-ref={entry.ref}
                      class="text-red-500 text-xs"
                    >
                      &times;
                    </button>
                  </div>
                  
                  <.live_img_preview entry={entry} class="mt-2 h-16 w-16 rounded-full object-cover" />
                  
                  <%= for err <- upload_errors(@uploads.avatar, entry) do %>
                    <div class="text-red-500 text-xs"><%= error_to_string(err) %></div>
                  <% end %>
                <% end %>
              </div>
              
              <%= for err <- upload_errors(@uploads.avatar) do %>
                <div class="text-red-500 text-xs"><%= error_to_string(err) %></div>
              <% end %>
            </div>
          </div>
        </div>
        
        <:actions>
          <.button class="w-full">Save Profile</.button>
        </:actions>
      </.simple_form>

      <div class="mt-10 text-center">
        <.link href={~p"/logout"} method="delete" class="text-sm font-semibold text-red-600 hover:underline">
          Sign Out
        </.link>
      </div>
    </div>
    """
  end

  defp error_to_string(:too_large), do: "File is too large (max 5MB)"
  defp error_to_string(:not_accepted), do: "Unacceptable file type (only .jpg, .jpeg, .png)"
  defp error_to_string(:too_many_files), do: "Too many files (max 1)"
  defp error_to_string(err), do: "Error: #{inspect(err)}"
end