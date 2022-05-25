defmodule MobaWeb.Pow.RegistrationView do
  use MobaWeb, :view

  alias Moba.{Game, Accounts}

  def current_hero(conn) do
    conn
    |> guest_user()
    |> Moba.current_pve_hero()
  end

  def guest_user(conn) do
    conn
    |> Plug.Conn.get_session(:guest_user_id)
    |> Accounts.get_user!()
  end

  def current_avatar(hero), do: Game.get_avatar!(hero.avatar.id)

  def creation_avatars, do: Game.list_creation_avatars()
end
