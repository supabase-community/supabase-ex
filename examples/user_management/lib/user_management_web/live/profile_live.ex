defmodule UserManagementWeb.ProfileLive do
  use UserManagementWeb, :live_view

  alias UserManagement.Profiles
  alias Supabase.Storage

  @impl true
  def mount(_params, _session, socket) do
    if user = socket.assigns.current_user do
      profile = Profiles.get_profile_by_user_id(user.id)
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
         max_file_size: 5_000_000
       )}
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

        # Create a temporary file and upload it
        temp_path = Path.join(System.tmp_dir(), file_name)
        File.write!(temp_path, file)

        # Upload the file to Supabase
        case Storage.from(client, "avatars")
             |> Storage.File.upload(temp_path, file_name, %{content_type: file_type}) do
          {:ok, %{path: _path}} ->
            # Clean up temporary file
            File.rm!(temp_path)

            # Get public URL
            {:ok, public_url} =
              Storage.from(client, "avatars")
              |> Storage.File.get_public_url(file_name)

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
    <div class="form-widget">
      <div style="margin-bottom: 2rem;">
        <div style="display: flex; align-items: center;">
          <div>
            <%= if @avatar_url do %>
              <img
                src={@avatar_url}
                alt="Avatar"
                class="avatar image"
                style="height: 10em; width: 10em;"
              />
            <% else %>
              <div class="avatar no-image" style="height: 10em; width: 10em;" />
            <% end %>
          </div>

          <div style="width: 10em; position: relative; margin-left: 1rem;">
            <.live_file_input
              upload={@uploads.avatar}
              style="position: absolute; visibility: hidden;"
              id="avatar-input"
            />
            <label class="button primary block" for="avatar-input">
              {if Enum.any?(@uploads.avatar.entries), do: "Uploading...", else: "Upload"}
            </label>

            <button
              :if={Enum.any?(@uploads.avatar.entries)}
              type="button"
              phx-click="upload-avatar"
              class="button primary block"
              style="margin-top: 0.5rem;"
            >
              Save Avatar
            </button>
          </div>
        </div>

        <div :if={Enum.any?(@uploads.avatar.entries)} style="margin-top: 1rem;">
          <%= for entry <- @uploads.avatar.entries do %>
            <div style="display: flex; align-items: center; margin-bottom: 0.5rem;">
              <span style="margin-right: 0.5rem;">{entry.client_name}</span>
              <button type="button" phx-click="cancel-upload" phx-value-ref={entry.ref}>
                &times;
              </button>
            </div>

            <.live_img_preview entry={entry} class="avatar image" style="height: 5em; width: 5em;" />

            <%= for err <- upload_errors(@uploads.avatar, entry) do %>
              <div style="color: red; font-size: 0.8rem;">{error_to_string(err)}</div>
            <% end %>
          <% end %>
        </div>

        <%= for err <- upload_errors(@uploads.avatar) do %>
          <div style="color: red; font-size: 0.8rem;">{error_to_string(err)}</div>
        <% end %>
      </div>

      <.simple_form for={@form} id="profile-form" phx-change="validate" phx-submit="save">
        <div>
          <label for="email">Email</label>
          <input id="email" type="text" value={@current_user.email} disabled />
        </div>

        <.input field={@form[:username]} type="text" label="Name" />
        <.input field={@form[:website]} type="url" label="Website" />

        <:actions>
          <.button class="primary block">Update</.button>
        </:actions>
      </.simple_form>

      <div>
        <.link href={~p"/logout"} method="delete" class="button block">
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
