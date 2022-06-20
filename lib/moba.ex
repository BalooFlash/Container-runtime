defmodule Moba do
  @moduledoc """
  High-level helpers, core variables and cross-context orchestration
  """

  alias Moba.{Accounts, Cleaner, Conductor, Game, Ranker}

  # General constants
  @damage_types %{normal: "normal", magic: "magic", pure: "pure"}
  @user_level_xp 10_000
  @base_hero_count 6
  @leagues %{
    0 => "Bronze League",
    1 => "Silver League",
    2 => "Gold League",
    3 => "Platinum League",
    4 => "Diamond League",
    5 => "Master League",
    6 => "Grandmaster League"
  }
  @pvp_tiers %{
    0 => "Herald",
    1 => "Herald Superior",
    2 => "Herald Elite",
    3 => "Guardian",
    4 => "Guardian Superior",
    5 => "Guardian Elite",
    6 => "Crusader",
    7 => "Crusader Superior",
    8 => "Crusader Elite",
    9 => "Archon",
    10 => "Supreme Archon",
    11 => "Ultimate Archon",
    12 => "Centurion",
    13 => "Gladiator",
    14 => "Champion",
    15 => "Legend",
    16 => "Ancient",
    17 => "Divine",
    18 => "Immortal"
  }
  @pve_tiers %{
    0 => "Initiate",
    1 => "Novice",
    2 => "Adept",
    3 => "Veteran",
    4 => "Expert",
    5 => "Master",
    6 => "Grandmaster",
    7 => "Invoker"
  }
  @turn_mp_regen_multiplier 0.01
  @season_quest_codes ["season", "season_master", "season_grandmaster", "season_perfect"]
  @current_ranking_date Timex.parse!("06-02-2022", "%d-%m-%Y", :strftime)
  @shard_buyback_minimum 5
  @max_season_tier 18
  @match_timeout_in_hours 24
  @normal_matchmaking_shards 5
  @elite_matchmaking_shards 15
  @minimum_duel_points 2
  @maximum_points_difference 200
  @duel_timer_in_seconds 60
  @turn_timer_in_seconds 30

  # PVE constants
  @total_pve_turns 25
  @turns_per_tier 5
  @base_xp 600
  @xp_increment 50
  @veteran_pve_tier 2
  @initial_gold 800
  @veteran_initial_gold 2000
  @items_base_price 400
  @buyback_multiplier 10
  @refresh_targets_count 5
  @maximum_total_farm 60_000
  @seconds_per_turn 2
  @max_pve_tier 7

  # League constants
  @platinum_league_tier 3
  @master_league_tier 5
  @max_league_tier 6
  @league_win_bonus 2000
  @boss_regeneration_multiplier 0.5
  @boss_win_bonus 2000

  def base_hero_count, do: @base_hero_count
  def items_base_price, do: @items_base_price
  def normal_items_price, do: @items_base_price * 1
  def rare_items_price, do: @items_base_price * 3
  def epic_items_price, do: @items_base_price * 6
  def legendary_items_price, do: @items_base_price * 12
  def damage_types, do: @damage_types
  def user_level_xp, do: @user_level_xp
  def leagues, do: @leagues
  def pvp_tiers, do: @pvp_tiers
  def pve_tiers, do: @pve_tiers
  def turn_mp_regen_multiplier, do: @turn_mp_regen_multiplier
  def season_quest_codes, do: @season_quest_codes
  def current_ranking_date, do: @current_ranking_date
  def shard_buyback_minimum, do: @shard_buyback_minimum
  def max_season_tier, do: @max_season_tier
  def match_timeout_in_hours, do: @match_timeout_in_hours
  def normal_matchmaking_shards, do: @normal_matchmaking_shards
  def elite_matchmaking_shards, do: @elite_matchmaking_shards
  def maximum_points_difference, do: @maximum_points_difference
  def minimum_duel_points(points) when points < @minimum_duel_points, do: @minimum_duel_points
  def minimum_duel_points(points), do: points
  def victory_duel_points(diff) when diff < -@maximum_points_difference or diff > @maximum_points_difference, do: 0
  def victory_duel_points(diff) when diff > -40 and diff < 40, do: 5
  def victory_duel_points(diff) when diff < 0, do: ceil(150 / abs(diff)) |> minimum_duel_points()
  def victory_duel_points(diff), do: ceil(diff * 0.15)
  def defeat_duel_points(diff), do: victory_duel_points(-diff)
  def tie_duel_points(diff) when diff < -@maximum_points_difference or diff > @maximum_points_difference, do: 0
  def tie_duel_points(diff) when diff < 0, do: -(ceil(-diff * 0.05) |> minimum_duel_points())
  def tie_duel_points(diff), do: ceil(diff * 0.05) |> minimum_duel_points()
  def duel_timer_in_seconds, do: @duel_timer_in_seconds
  def turn_timer_in_seconds, do: @turn_timer_in_seconds

  def total_pve_turns(0), do: @total_pve_turns - 10
  def total_pve_turns(1), do: @total_pve_turns - 5
  def total_pve_turns(_), do: @total_pve_turns
  def turns_per_tier, do: @turns_per_tier
  def base_xp, do: @base_xp
  def xp_increment, do: @xp_increment
  def veteran_pve_tier, do: @veteran_pve_tier
  def initial_gold(%{pve_tier: tier}) when tier > 0, do: @veteran_initial_gold
  def initial_gold(_), do: @initial_gold
  def buyback_multiplier, do: @buyback_multiplier
  def refresh_targets_count, do: @refresh_targets_count
  def maximum_total_farm, do: @maximum_total_farm
  def seconds_per_turn, do: @seconds_per_turn
  def farm_per_turn(0), do: 800..1200
  def farm_per_turn(1), do: 850..1200
  def farm_per_turn(2), do: 900..1200
  def farm_per_turn(3), do: 950..1200
  def farm_per_turn(_), do: 1000..1200
  def pve_battle_rewards("weak", pve_tier) when pve_tier < @veteran_pve_tier, do: 500
  def pve_battle_rewards("moderate", pve_tier) when pve_tier < @veteran_pve_tier, do: 600
  def pve_battle_rewards("moderate", _), do: 500
  def pve_battle_rewards("strong", _), do: 600
  def max_pve_tier, do: @max_pve_tier
  def refresh_targets_count(4), do: 5
  def refresh_targets_count(5), do: 10
  def refresh_targets_count(6), do: 15
  def refresh_targets_count(7), do: 20

  def platinum_league_tier, do: @platinum_league_tier
  def master_league_tier, do: @master_league_tier
  def max_league_tier, do: @max_league_tier
  def league_win_bonus, do: @league_win_bonus
  def league_buff_multiplier(0, league_tier) when league_tier < 3, do: 0.6
  def league_buff_multiplier(1, league_tier) when league_tier < 3, do: 0.45
  def league_buff_multiplier(2, league_tier) when league_tier < 3, do: 0.3
  def league_buff_multiplier(3, league_tier) when league_tier < 3, do: 0.15
  def league_buff_multiplier(_, _), do: 0
  def boss_regeneration_multiplier, do: @boss_regeneration_multiplier
  def boss_win_bonus, do: @boss_win_bonus
  def max_available_league(0), do: 4
  def max_available_league(1), do: 5
  def max_available_league(_), do: 6

  def avatar_minimum_stats() do
    %{
      total_hp: 200,
      total_mp: 10,
      atk: 12,
      power: 0,
      armor: 0,
      speed: 0
    }
  end

  def avatar_stat_units() do
    %{
      total_hp: 5,
      total_mp: 4,
      atk: 1,
      power: 1.4,
      armor: 1,
      speed: 5
    }
  end

  def current_pve_hero(%{current_pve_hero_id: hero_id}), do: Game.get_hero!(hero_id)

  def xp_to_next_hero_level(level) when level < 1, do: 0
  def xp_to_next_hero_level(level), do: base_xp() + (level - 2) * xp_increment()

  def xp_until_hero_level(level) when level < 2, do: 0
  def xp_until_hero_level(level), do: xp_to_next_hero_level(level) + xp_until_hero_level(level - 1)

  defdelegate server_update!(match \\ Moba.current_match()), to: Conductor

  def start! do
    IO.puts("Starting match...")
    Conductor.start_match!()
    Cleaner.cleanup_old_records()
  end

  def regenerate_resources! do
    IO.puts("Regenerating resources...")
    Conductor.regenerate_resources!()
  end

  def regenerate_pve_bots!(bot_level_range \\ 0..35) do
    IO.puts("Generating new PVE bots...")
    Conductor.regenerate_pve_bots!(bot_level_range)
  end

  def regenerate_pvp_bots! do
    IO.puts("Generating new PVP bots...")
    Conductor.regenerate_pvp_bots!()
  end

  defdelegate current_match, to: Game

  def create_current_pve_hero!(
        attrs,
        user,
        avatar,
        skills
      ) do
    hero = Game.create_hero!(attrs, user, avatar, skills)
    Accounts.set_current_pve_hero!(user, hero.id)
    hero
  end

  @doc """
  Game pve_ranking is defined by who has the highest total_farm (gold + xp)
  """
  def update_pve_ranking do
    if test?(), do: Game.update_pve_ranking!(), else: GenServer.cast(Ranker, :pve)
  end

  @doc """
  Accounts ranking is defined by who has the highest season_points
  """
  def update_pvp_ranking do
    if test?(), do: Accounts.update_ranking!(), else: GenServer.cast(Ranker, :pvp)
  end

  def auto_matchmaking!(user), do: Game.create_matchmaking!(user, Accounts.matchmaking_opponent(user), true)

  def bot_matchmaking!(user), do: Game.create_matchmaking!(user, Accounts.bot_opponent(user), false)

  def normal_matchmaking!(user), do: Game.create_matchmaking!(user, Accounts.normal_opponent(user), false)

  def elite_matchmaking!(user), do: Game.create_matchmaking!(user, Accounts.elite_opponent(user), false)

  def basic_attack, do: Game.basic_attack()

  def add_user_experience(user, experience), do: Accounts.add_experience(user, experience)

  def update_user!(user, updates), do: Accounts.update_user!(user, updates)

  def restarting?, do: is_nil(Game.current_match().last_server_update_at)

  def cached_items do
    match_id = if restarting?(), do: Game.last_match().id, else: Game.current_match().id

    case Cachex.get(:game_cache, "items-#{match_id}") do
      {:ok, nil} -> put_items_cache(match_id)
      {:ok, items} -> items
    end
  end

  def struct_from_map(a_map, as: a_struct) do
    # Find the keys within the map
    keys =
      Map.keys(a_struct)
      |> Enum.filter(fn x -> x != :__struct__ end)

    # Process map, checking for both string / atom keys
    processed_map =
      for key <- keys, into: %{} do
        value = Map.get(a_map, key) || Map.get(a_map, to_string(key))
        {key, value}
      end

    a_struct = Map.merge(a_struct, processed_map)
    a_struct
  end

  def run_async(fun) do
    if test?() do
      fun.()
    else
      Task.start(fun)
    end
  end

  defp put_items_cache(match_id) do
    items = Game.shop_list()
    Cachex.put(:game_cache, "items-#{match_id}", items)
    items
  end

  defp test?, do: Application.get_env(:moba, :env) == :test
end
