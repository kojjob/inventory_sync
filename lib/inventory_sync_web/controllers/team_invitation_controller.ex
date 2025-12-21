defmodule InventorySyncWeb.TeamInvitationController do
  use InventorySyncWeb, :controller

  alias InventorySync.Accounts

  def show(conn, %{"token" => token}) do
    case Accounts.get_team_member_by_invitation_token(token) do
      {team_member, _token_record} ->
        # If user is already logged in, accept invitation automatically
        if conn.assigns[:current_user] do
          accept_invitation_for_user(conn, team_member, conn.assigns.current_user, token)
        else
          # Store token in session and redirect to registration
          conn
          |> put_session(:invitation_token, token)
          |> put_flash(:info, "Please create an account or log in to accept the invitation.")
          |> redirect(to: ~p"/users/register")
        end

      nil ->
        conn
        |> put_flash(:error, "Invitation link is invalid or has expired.")
        |> redirect(to: ~p"/users/log-in")
    end
  end

  defp accept_invitation_for_user(conn, team_member, user, _token) do
    case Accounts.accept_team_invitation(team_member, user, %{}) do
      {:ok, _team_member} ->
        conn
        |> put_flash(:info, "You have successfully joined the team!")
        |> redirect(to: ~p"/")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "There was an error accepting the invitation.")
        |> redirect(to: ~p"/")
    end
  end
end
