defmodule Moba.Admin.Duels do
  @moduledoc """
  Admin functions for managing Matches, mostly generated by Torch package.
  """

  alias Moba.{Repo, Game}
  alias Game.Schema.Duel

  import Ecto.Query

  def list_recent do
    Repo.all(from d in Duel, limit: 20, join: u in assoc(d, :user), where: u.is_bot == false, order_by: [desc: d.id])
    |> Repo.preload([:user, :opponent, :winner])
  end

  def get!(id), do: Repo.get!(Duel, id)
end
