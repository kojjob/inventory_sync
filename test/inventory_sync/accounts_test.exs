defmodule InventorySync.AccountsTest do
  use InventorySync.DataCase

  alias InventorySync.Accounts

  import InventorySync.AccountsFixtures
  alias InventorySync.Accounts.{User, UserToken}

  describe "get_user_by_email/1" do
    test "does not return the user if the email does not exist" do
      refute Accounts.get_user_by_email("unknown@example.com")
    end

    test "returns the user if the email exists" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user_by_email(user.email)
    end
  end

  describe "get_user_by_email_and_password/2" do
    test "does not return the user if the email does not exist" do
      refute Accounts.get_user_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the user if the password is not valid" do
      user = user_fixture() |> set_password()
      refute Accounts.get_user_by_email_and_password(user.email, "invalid")
    end

    test "returns the user if the email and password are valid" do
      %{id: id} = user = user_fixture() |> set_password()

      assert %User{id: ^id} =
               Accounts.get_user_by_email_and_password(user.email, valid_user_password())
    end
  end

  describe "get_user!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_user!(-1)
      end
    end

    test "returns the user with the given id" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user!(user.id)
    end
  end

  describe "register_user/1" do
    test "requires email to be set" do
      {:error, changeset} = Accounts.register_user(%{})

      assert %{email: ["can't be blank"]} = errors_on(changeset)
    end

    test "validates email when given" do
      {:error, changeset} = Accounts.register_user(%{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum values for email for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.register_user(%{email: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness" do
      %{email: email} = user_fixture()
      {:error, changeset} = Accounts.register_user(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the uppercased email too, to check that email case is ignored.
      {:error, changeset} = Accounts.register_user(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers users without password" do
      email = unique_user_email()
      {:ok, user} = Accounts.register_user(valid_user_attributes(email: email))
      assert user.email == email
      assert is_nil(user.hashed_password)
      assert is_nil(user.confirmed_at)
      assert is_nil(user.password)
    end
  end

  describe "sudo_mode?/2" do
    test "validates the authenticated_at time" do
      now = DateTime.utc_now()

      assert Accounts.sudo_mode?(%User{authenticated_at: DateTime.utc_now()})
      assert Accounts.sudo_mode?(%User{authenticated_at: DateTime.add(now, -19, :minute)})
      refute Accounts.sudo_mode?(%User{authenticated_at: DateTime.add(now, -21, :minute)})

      # minute override
      refute Accounts.sudo_mode?(
               %User{authenticated_at: DateTime.add(now, -11, :minute)},
               -10
             )

      # not authenticated
      refute Accounts.sudo_mode?(%User{})
    end
  end

  describe "change_user_email/3" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_email(%User{})
      assert changeset.required == [:email]
    end
  end

  describe "deliver_user_update_email_instructions/3" do
    setup do
      %{user: user_fixture()}
    end

    test "sends token through notification", %{user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_update_email_instructions(user, "current@example.com", url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "change:current@example.com"
    end
  end

  describe "update_user_email/2" do
    setup do
      user = unconfirmed_user_fixture()
      email = unique_user_email()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_update_email_instructions(%{user | email: email}, user.email, url)
        end)

      %{user: user, token: token, email: email}
    end

    test "updates the email with a valid token", %{user: user, token: token, email: email} do
      assert {:ok, %{email: ^email}} = Accounts.update_user_email(user, token)
      changed_user = Repo.get!(User, user.id)
      assert changed_user.email != user.email
      assert changed_user.email == email
      refute Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email with invalid token", %{user: user} do
      assert Accounts.update_user_email(user, "oops") ==
               {:error, :transaction_aborted}

      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email if user email changed", %{user: user, token: token} do
      assert Accounts.update_user_email(%{user | email: "current@example.com"}, token) ==
               {:error, :transaction_aborted}

      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email if token expired", %{user: user, token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])

      assert Accounts.update_user_email(user, token) ==
               {:error, :transaction_aborted}

      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "change_user_password/3" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_password(%User{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        Accounts.change_user_password(
          %User{},
          %{
            "password" => "new valid password"
          },
          hash_password: false
        )

      assert changeset.valid?
      assert get_change(changeset, :password) == "new valid password"
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_user_password/2" do
    setup do
      %{user: user_fixture()}
    end

    test "validates password", %{user: user} do
      {:error, changeset} =
        Accounts.update_user_password(user, %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{user: user} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.update_user_password(user, %{password: too_long})

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{user: user} do
      {:ok, {user, expired_tokens}} =
        Accounts.update_user_password(user, %{
          password: "new valid password"
        })

      assert expired_tokens == []
      assert is_nil(user.password)
      assert Accounts.get_user_by_email_and_password(user.email, "new valid password")
    end

    test "deletes all tokens for the given user", %{user: user} do
      _ = Accounts.generate_user_session_token(user)

      {:ok, {_, _}} =
        Accounts.update_user_password(user, %{
          password: "new valid password"
        })

      refute Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "generate_user_session_token/1" do
    setup do
      %{user: user_fixture()}
    end

    test "generates a token", %{user: user} do
      token = Accounts.generate_user_session_token(user)
      assert user_token = Repo.get_by(UserToken, token: token)
      assert user_token.context == "session"
      assert user_token.authenticated_at != nil

      # Creating the same token for another user should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%UserToken{
          token: user_token.token,
          user_id: user_fixture().id,
          context: "session"
        })
      end
    end

    test "duplicates the authenticated_at of given user in new token", %{user: user} do
      user = %{user | authenticated_at: DateTime.add(DateTime.utc_now(:second), -3600)}
      token = Accounts.generate_user_session_token(user)
      assert user_token = Repo.get_by(UserToken, token: token)
      assert user_token.authenticated_at == user.authenticated_at
      assert DateTime.compare(user_token.inserted_at, user.authenticated_at) == :gt
    end
  end

  describe "get_user_by_session_token/1" do
    setup do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)
      %{user: user, token: token}
    end

    test "returns user by token", %{user: user, token: token} do
      assert {session_user, token_inserted_at} = Accounts.get_user_by_session_token(token)
      assert session_user.id == user.id
      assert session_user.authenticated_at != nil
      assert token_inserted_at != nil
    end

    test "does not return user for invalid token" do
      refute Accounts.get_user_by_session_token("oops")
    end

    test "does not return user for expired token", %{token: token} do
      dt = ~N[2020-01-01 00:00:00]
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: dt, authenticated_at: dt])
      refute Accounts.get_user_by_session_token(token)
    end
  end

  describe "get_user_by_magic_link_token/1" do
    setup do
      user = user_fixture()
      {encoded_token, _hashed_token} = generate_user_magic_link_token(user)
      %{user: user, token: encoded_token}
    end

    test "returns user by token", %{user: user, token: token} do
      assert session_user = Accounts.get_user_by_magic_link_token(token)
      assert session_user.id == user.id
    end

    test "does not return user for invalid token" do
      refute Accounts.get_user_by_magic_link_token("oops")
    end

    test "does not return user for expired token", %{token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_user_by_magic_link_token(token)
    end
  end

  describe "login_user_by_magic_link/1" do
    test "confirms user and expires tokens" do
      user = unconfirmed_user_fixture()
      refute user.confirmed_at
      {encoded_token, hashed_token} = generate_user_magic_link_token(user)

      assert {:ok, {user, [%{token: ^hashed_token}]}} =
               Accounts.login_user_by_magic_link(encoded_token)

      assert user.confirmed_at
    end

    test "returns user and (deleted) token for confirmed user" do
      user = user_fixture()
      assert user.confirmed_at
      {encoded_token, _hashed_token} = generate_user_magic_link_token(user)
      assert {:ok, {^user, []}} = Accounts.login_user_by_magic_link(encoded_token)
      # one time use only
      assert {:error, :not_found} = Accounts.login_user_by_magic_link(encoded_token)
    end

    test "raises when unconfirmed user has password set" do
      user = unconfirmed_user_fixture()
      {1, nil} = Repo.update_all(User, set: [hashed_password: "hashed"])
      {encoded_token, _hashed_token} = generate_user_magic_link_token(user)

      assert_raise RuntimeError, ~r/magic link log in is not allowed/, fn ->
        Accounts.login_user_by_magic_link(encoded_token)
      end
    end
  end

  describe "delete_user_session_token/1" do
    test "deletes the token" do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)
      assert Accounts.delete_user_session_token(token) == :ok
      refute Accounts.get_user_by_session_token(token)
    end
  end

  describe "deliver_login_instructions/2" do
    setup do
      %{user: unconfirmed_user_fixture()}
    end

    test "sends token through notification", %{user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_login_instructions(user, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "login"
    end
  end

  describe "inspect/2 for the User module" do
    test "does not include password" do
      refute inspect(%User{password: "123456"}) =~ "password: \"123456\""
    end
  end

  describe "deliver_team_invitation/4" do
    setup do
      inviting_user = user_fixture()
      email = unique_user_email()
      team_member_params = %{"email" => email, "role" => "Admin", "title" => "Manager"}
      %{inviting_user: inviting_user, email: email, team_member_params: team_member_params}
    end

    test "creates team member with Invited status", %{inviting_user: inviting_user, email: email, team_member_params: team_member_params} do
      invitation_url_fun = fn _token -> "http://example.com/invitations/accept/token" end

      {:ok, {team_member, _email}} = Accounts.deliver_team_invitation(email, team_member_params, inviting_user, invitation_url_fun)

      assert team_member.email == email
      assert team_member.role == "Admin"
      assert team_member.title == "Manager"
      assert team_member.status == "Invited"
      assert is_nil(team_member.user_id)
    end

    test "creates invitation token", %{inviting_user: inviting_user, email: email, team_member_params: team_member_params} do
      # Extract token from email
      token =
        extract_user_token(fn url ->
          {:ok, {_team_member, email_struct}} = Accounts.deliver_team_invitation(email, team_member_params, inviting_user, url)
          email_struct
        end)

      {:ok, token_binary} = Base.url_decode64(token, padding: false)
      hashed_token = :crypto.hash(:sha256, token_binary)

      assert user_token = Repo.get_by(UserToken, token: hashed_token)
      assert user_token.context == "invitation"
      assert user_token.sent_to == email
    end

    test "sends invitation email", %{inviting_user: inviting_user, email: email, team_member_params: team_member_params} do
      token =
        extract_user_token(fn url ->
          {:ok, {_team_member, email_struct}} = Accounts.deliver_team_invitation(email, team_member_params, inviting_user, url)
          email_struct
        end)

      assert token
    end

    test "returns error for invalid email", %{inviting_user: inviting_user, team_member_params: team_member_params} do
      invalid_params = Map.put(team_member_params, "email", "invalid")
      invitation_url_fun = fn _token -> "http://example.com/invitations/accept/token" end

      {:error, changeset} = Accounts.deliver_team_invitation("invalid", invalid_params, inviting_user, invitation_url_fun)

      assert %{email: ["must be a valid email"]} = errors_on(changeset)
    end

    test "returns error for duplicate email", %{inviting_user: inviting_user, email: email, team_member_params: team_member_params} do
      invitation_url_fun = fn _token -> "http://example.com/invitations/accept/token" end

      # Create first invitation
      {:ok, {_team_member, _email}} = Accounts.deliver_team_invitation(email, team_member_params, inviting_user, invitation_url_fun)

      # Try to create duplicate
      {:error, changeset} = Accounts.deliver_team_invitation(email, team_member_params, inviting_user, invitation_url_fun)

      assert "has already been taken" in errors_on(changeset).email
    end
  end

  describe "get_team_member_by_invitation_token/1" do
    setup do
      inviting_user = user_fixture()
      email = unique_user_email()
      team_member_params = %{"email" => email, "role" => "Admin"}

      token =
        extract_user_token(fn url ->
          {:ok, {_team_member, email_struct}} = Accounts.deliver_team_invitation(email, team_member_params, inviting_user, url)
          email_struct
        end)

      %{token: token, email: email}
    end

    test "returns team member and token record for valid token", %{token: token, email: email} do
      assert {team_member, token_record} = Accounts.get_team_member_by_invitation_token(token)
      assert team_member.email == email
      assert team_member.status == "Invited"
      assert token_record.context == "invitation"
    end

    test "does not return team member for invalid token" do
      refute Accounts.get_team_member_by_invitation_token("oops")
    end

    test "does not return team member for expired token", %{token: token} do
      # Update all tokens to be expired (8 days old)
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])

      refute Accounts.get_team_member_by_invitation_token(token)
    end

    test "does not return team member if already accepted", %{token: token} do
      # Accept the invitation
      {team_member, _token_record} = Accounts.get_team_member_by_invitation_token(token)
      user = user_fixture()
      {:ok, _updated_team_member} = Accounts.accept_team_invitation(team_member, user, %{})

      # Token should be deleted after acceptance
      refute Accounts.get_team_member_by_invitation_token(token)
    end
  end

  describe "accept_team_invitation/3" do
    setup do
      inviting_user = user_fixture()
      email = unique_user_email()
      team_member_params = %{"email" => email, "role" => "Editor", "title" => "Developer"}

      token =
        extract_user_token(fn url ->
          {:ok, {_team_member, email_struct}} = Accounts.deliver_team_invitation(email, team_member_params, inviting_user, url)
          email_struct
        end)

      {team_member, _token_record} = Accounts.get_team_member_by_invitation_token(token)
      accepting_user = user_fixture()

      %{team_member: team_member, accepting_user: accepting_user, token: token}
    end

    test "links user to team member", %{team_member: team_member, accepting_user: accepting_user} do
      {:ok, updated_team_member} = Accounts.accept_team_invitation(team_member, accepting_user, %{})

      assert updated_team_member.user_id == accepting_user.id
    end

    test "updates status to Active", %{team_member: team_member, accepting_user: accepting_user} do
      {:ok, updated_team_member} = Accounts.accept_team_invitation(team_member, accepting_user, %{})

      assert updated_team_member.status == "Active"
    end

    test "updates name if provided", %{team_member: team_member, accepting_user: accepting_user} do
      {:ok, updated_team_member} = Accounts.accept_team_invitation(team_member, accepting_user, %{"name" => "John Doe"})

      assert updated_team_member.name == "John Doe"
    end

    test "deletes invitation token", %{team_member: team_member, accepting_user: accepting_user, token: token} do
      {:ok, _updated_team_member} = Accounts.accept_team_invitation(team_member, accepting_user, %{})

      # Token should be deleted
      refute Accounts.get_team_member_by_invitation_token(token)

      # Verify no tokens exist for this team member
      {:ok, token_binary} = Base.url_decode64(token, padding: false)
      hashed_token = :crypto.hash(:sha256, token_binary)
      refute Repo.get_by(UserToken, token: hashed_token)
    end

    test "returns error if team member already has a user", %{team_member: team_member, accepting_user: accepting_user} do
      # Accept invitation first time
      {:ok, accepted_team_member} = Accounts.accept_team_invitation(team_member, accepting_user, %{})

      # Try to accept again with different user (using the updated team_member with user_id set)
      another_user = user_fixture()
      {:error, changeset} = Accounts.accept_team_invitation(accepted_team_member, another_user, %{})

      assert "has already been accepted" in errors_on(changeset).user_id
    end

    test "preserves role and title from invitation", %{team_member: team_member, accepting_user: accepting_user} do
      {:ok, updated_team_member} = Accounts.accept_team_invitation(team_member, accepting_user, %{})

      assert updated_team_member.role == "Editor"
      assert updated_team_member.title == "Developer"
    end
  end
end
