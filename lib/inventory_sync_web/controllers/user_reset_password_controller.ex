defmodule InventorySyncWeb.UserResetPasswordController do
  use InventorySyncWeb, :controller

  alias InventorySync.Accounts

  import Phoenix.Component, only: [to_form: 1]

  def new(conn, _params) do
    render(conn, :new, form: to_form(%{}))
  end

  def create(conn, %{"user" => %{"email" => email}}) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_reset_password_instructions(
        user,
        &url(~p"/users/reset-password/#{&1}")
      )
    end

    # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
    conn
    |> put_flash(
      :info,
      "If your email is in our system, you will receive instructions to reset your password shortly."
    )
    |> redirect(to: ~p"/users/log-in")
  end

  def edit(conn, %{"token" => token}) do
    if user = Accounts.get_user_by_reset_password_token(token) do
      conn
      |> assign(:user, user)
      |> assign(:token, token)
      |> render(:edit, changeset: Accounts.change_user_password(user))
    else
      conn
      |> put_flash(:error, "Reset password link is invalid or it has expired.")
      |> redirect(to: ~p"/users/log-in")
    end
  end

  # Do not log in the user after reset password to avoid a
  # leaked token giving the user access to the account.
  def update(conn, %{"token" => token, "user" => user_params}) do
    if user = Accounts.get_user_by_reset_password_token(token) do
      case Accounts.reset_user_password(user, user_params) do
        {:ok, _user} ->
          conn
          |> put_flash(:info, "Password reset successfully.")
          |> redirect(to: ~p"/users/log-in")

        {:error, changeset} ->
          conn
          |> assign(:user, user)
          |> assign(:token, token)
          |> render(:edit, changeset: changeset)
      end
    else
      conn
      |> put_flash(:error, "Reset password link is invalid or it has expired.")
      |> redirect(to: ~p"/users/log-in")
    end
  end
end
