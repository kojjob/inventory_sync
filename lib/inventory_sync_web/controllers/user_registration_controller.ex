defmodule InventorySyncWeb.UserRegistrationController do
  use InventorySyncWeb, :controller

  alias InventorySync.Accounts
  alias InventorySync.Accounts.User

  def new(conn, _params) do
    changeset = Accounts.change_user_email(%User{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        # Check if there's an invitation token in the session
        conn =
          case get_session(conn, :invitation_token) do
            nil ->
              # No invitation, send normal login instructions
              {:ok, _} =
                Accounts.deliver_login_instructions(
                  user,
                  &url(~p"/users/log-in/#{&1}")
                )

              put_flash(
                conn,
                :info,
                "An email was sent to #{user.email}, please access it to confirm your account."
              )

            token ->
              # Accept invitation for this new user
              case Accounts.get_team_member_by_invitation_token(token) do
                {team_member, _token_record} ->
                  case Accounts.accept_team_invitation(team_member, user, %{}) do
                    {:ok, _team_member} ->
                      # Send login instructions and notify about team membership
                      {:ok, _} =
                        Accounts.deliver_login_instructions(
                          user,
                          &url(~p"/users/log-in/#{&1}")
                        )

                      conn
                      |> delete_session(:invitation_token)
                      |> put_flash(
                        :info,
                        "Account created! An email was sent to #{user.email} to confirm your account and join the team."
                      )

                    {:error, _changeset} ->
                      # Invitation acceptance failed, but user is created
                      {:ok, _} =
                        Accounts.deliver_login_instructions(
                          user,
                          &url(~p"/users/log-in/#{&1}")
                        )

                      conn
                      |> delete_session(:invitation_token)
                      |> put_flash(
                        :info,
                        "An email was sent to #{user.email}, please access it to confirm your account."
                      )
                  end

                nil ->
                  # Invalid invitation token, proceed normally
                  {:ok, _} =
                    Accounts.deliver_login_instructions(
                      user,
                      &url(~p"/users/log-in/#{&1}")
                    )

                  conn
                  |> delete_session(:invitation_token)
                  |> put_flash(
                    :info,
                    "An email was sent to #{user.email}, please access it to confirm your account."
                  )
              end
          end

        redirect(conn, to: ~p"/users/log-in")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end
end
