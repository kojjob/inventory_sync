defmodule InventorySyncWeb.Api.V1.ErrorJSON do
  @moduledoc """
  JSON error responses for the API.

  Provides standardized error response formats.
  """

  @doc """
  Renders a not found error.
  """
  def not_found(_assigns) do
    %{error: "not_found"}
  end

  @doc """
  Renders a forbidden error (insufficient permissions).
  """
  def forbidden(_assigns) do
    %{error: "forbidden"}
  end

  @doc """
  Renders changeset validation errors.
  """
  def changeset_errors(%{changeset: changeset}) do
    %{errors: translate_errors(changeset)}
  end

  @doc """
  Renders a generic error message.
  """
  def error(%{message: message}) do
    %{error: message}
  end

  @doc """
  Renders a bad request error with message.
  """
  def bad_request(%{message: message}) do
    %{error: "bad_request", message: message}
  end

  @doc """
  Renders a not implemented error for stub endpoints.
  """
  def not_implemented(_assigns) do
    %{
      error: "not_implemented",
      message: "This feature is not yet implemented. Coming soon in Phase 2."
    }
  end

  # Translates changeset errors to a map of field => [error_messages]
  defp translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
