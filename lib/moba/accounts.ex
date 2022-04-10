defmodule Moba.Accounts do
  @moduledoc """
  Top-level domain of all account-wide logic

  As a top-level domain, it can access its siblings like Engine and Game, its parent (Moba)
  and all of its children (Users, Messages, etc). It cannot, however, access children of its
  siblings.
  """

  alias Moba.Accounts
  alias Accounts.{Users, Messages, Unlocks}

  # USERS

  def get_user!(id), do: Users.get!(id)

  def get_user_by_username(username), do: Users.get_by_username(username)

  def get_user_with_unlocks!(id), do: Users.get_with_unlocks!(id)

  def get_user_with_current_heroes!(id), do: Users.get_with_current_heroes!(id)

  def create_user(attrs), do: Users.create(attrs)

  def update_user!(user, attrs), do: Users.update!(user, attrs)

  defdelegate update_tutorial_step!(user, step), to: Users

  defdelegate update_preferences!(user, preferences), to: Users

  defdelegate add_experience(user, experience), to: Users

  defdelegate create_guest(conn), to: Users

  defdelegate set_online_now(user), to: Users

  defdelegate set_available!(user), to: Users

  defdelegate set_unavailable!(user), to: Users

  defdelegate search(user), to: Users

  defdelegate duel_opponents(user), to: Users

  # Player-related, should be extracted to Game context eventually: user -> player -> heroes

  defdelegate set_current_pve_hero!(user, hero_id), to: Users

  defdelegate season_points_for(tier), to: Users

  defdelegate season_tier_for(season_points), to: Users

  def user_duel_updates!(nil, _, _), do: nil

  def user_duel_updates!(user, duel_type, updates), do: Users.duel_updates!(user, duel_type, updates)

  defdelegate ranking(limit), to: Users

  def update_ranking! do
    Users.update_ranking!()
    MobaWeb.broadcast("user-ranking", "ranking", %{})
  end

  defdelegate update_collection!(user, hero_collection), to: Users

  defdelegate reset_unread_messages_count(user), to: Users

  defdelegate increment_unread_messages_count_for_all_online_except(user), to: Users

  defdelegate shard_buyback_price(user), to: Users

  defdelegate shard_buyback!(user), to: Users

  defdelegate normal_opponent(user), to: Users

  defdelegate elite_opponent(user), to: Users

  defdelegate bot_opponent(user), to: Users

  defdelegate manage_match_history(user, opponent), to: Users

  defdelegate normal_matchmaking_count(user), to: Users

  defdelegate elite_matchmaking_count(user), to: Users

  defdelegate closest_bot_time(user), to: Users

  # MESSAGES

  def latest_messages(channel, topic, limit), do: Messages.latest(channel, topic, limit)

  def get_message!(id), do: Messages.get!(id)

  def change_message(attrs \\ %{}), do: Messages.change(attrs)

  def create_message!(attrs \\ %{}) do
    message = Messages.create!(attrs)
    MobaWeb.broadcast(message.channel, message.topic, message)
    message
  end

  def delete_message(message), do: Messages.delete(message)

  # UNLOCKS

  def create_unlock!(user, resource), do: Unlocks.create!(user, resource)

  def unlocked_codes_for(user), do: Unlocks.resource_codes_for(user)

  def price_to_unlock(resource), do: Unlocks.price(resource)
end
