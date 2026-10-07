defmodule Supabase.ChangesetHelpers do
  @moduledoc "Shared helpers for asserting on changesets in tests."

  @doc """
  Returns a map of field => [messages] for the given changeset,
  with `%{...}` placeholders already interpolated.
  """
  def errors_on(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
