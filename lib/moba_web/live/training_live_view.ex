defmodule MobaWeb.TrainingLiveView do
  use MobaWeb, :live_view

  alias MobaWeb.{Tutorial, Shop, TrainingView}

  def mount(_, _, %{assigns: %{current_hero: hero}} = socket) do
    hero = Game.maybe_finish_pve(hero)

    cond do
      hero && hero.finished_at ->
        {:ok, socket |> redirect(to: Routes.live_path(socket, MobaWeb.HeroLiveView, hero.id))}

      hero ->
        if connected?(socket) do
          Game.subscribe_to_hero(hero.id)
          Tutorial.subscribe(hero.user_id)
        end

        Cachex.del(:game_cache, hero.user_id)
        targets = Game.list_targets(hero)
        targets = if length(targets) > 0, do: targets, else: Game.generate_targets!(hero) |> Game.list_targets()
        farm_tab = current_farm_tab(hero)
        if Enum.member?(["meditation", "mine"], farm_tab), do: time_trigger()

        {:ok,
         assign(socket,
           current_hero: hero,
           targets: targets,
           tutorial_step: hero.user.tutorial_step,
           pending_battle: Engine.pending_battle(hero.id),
           farm_tab: farm_tab,
           farm_rewards: [],
           selected_turns: hero.pve_current_turns,
           current_time: Timex.now(),
           farm_rewards: farm_rewards_for(hero, "meditating"),
           sidebar_code: "training"
         )}

      true ->
        {:ok, socket |> redirect(to: "/base")}
    end
  end

  def handle_params(_params, _uri, %{assigns: %{current_hero: hero}} = socket) do
    socket = if hero.gold >= 400 && length(hero.items) > 0, do: Tutorial.next_step(socket, 6), else: socket

    {:noreply, socket}
  end

  def handle_event("battle", %{"id" => id}, socket) do
    battle = Game.get_target!(id) |> Engine.create_pve_battle!()

    {:noreply,
     socket
     |> Tutorial.next_step(2)
     |> push_redirect(to: Routes.live_path(socket, MobaWeb.BattleLiveView, battle.id))}
  end

  def handle_event("refresh-targets", _, %{assigns: %{current_hero: hero}} = socket) do
    hero = Game.refresh_targets!(hero)
    {:noreply, assign(socket, current_hero: hero, targets: Game.list_targets(hero))}
  end

  def handle_event("league", _, %{assigns: %{current_hero: hero}} = socket) do
    socket = Tutorial.next_step(socket, 10)

    battle =
      hero
      |> Game.prepare_league_challenge!()
      |> Engine.create_league_battle!()

    {:noreply, socket |> push_redirect(to: Routes.live_path(socket, MobaWeb.BattleLiveView, battle.id))}
  end

  def handle_event("buyback", _, %{assigns: %{current_hero: hero}} = socket) do
    hero = Game.buyback!(hero)
    Game.broadcast_to_hero(hero.id)
    {:noreply, assign(socket, current_hero: hero)}
  end

  def handle_event("shard-buyback", _, %{assigns: %{current_hero: hero}} = socket) do
    hero = Game.shard_buyback!(hero)
    Game.broadcast_to_hero(hero.id)
    {:noreply, assign(socket, current_hero: hero)}
  end

  def handle_event("restart", _, %{assigns: %{current_hero: hero, current_user: user}} = socket) do
    Game.archive_hero!(hero)
    skills = Enum.map(hero.active_build.skills, &Game.get_skill_by_code!(&1.code, true, 1))
    Moba.create_current_pve_hero!(%{name: hero.name}, user, hero.avatar, skills)

    {:noreply, socket |> redirect(to: "/training")}
  end

  def handle_event("show-meditation", _, %{assigns: %{current_hero: hero}} = socket) do
    time_trigger()
    {:noreply, assign(socket, farm_tab: "meditation", farm_rewards: farm_rewards_for(hero, "meditating"))}
  end

  def handle_event("show-mine", _, %{assigns: %{current_hero: hero}} = socket) do
    time_trigger()
    {:noreply, assign(socket, farm_tab: "mine", farm_rewards: farm_rewards_for(hero, "mining"))}
  end

  def handle_event("show-gank", _, socket) do
    {:noreply, assign(socket, farm_tab: "gank")}
  end

  def handle_event("tutorial3", _, socket) do
    {:noreply, socket |> Tutorial.next_step(3) |> Shop.open()}
  end

  def handle_event("tutorial5", _, socket) do
    {:noreply, socket |> Tutorial.next_step(5)}
  end

  def handle_event("finish-tutorial", _, socket) do
    {:noreply, Tutorial.finish_training(socket)}
  end

  def handle_event("select-turns", params, %{assigns: %{current_hero: hero}} = socket) do
    turns = String.to_integer(params["turns"])
    turns = if turns > hero.pve_current_turns, do: hero.pve_current_turns, else: turns
    {:noreply, assign(socket, selected_turns: turns)}
  end

  def handle_event(
        "start-farming",
        %{"state" => state},
        %{assigns: %{current_hero: hero, selected_turns: turns}} = socket
      )
      when state in ["meditating", "mining"] do
    updated = Game.start_farming!(hero, state, turns)
    time_trigger()
    {:noreply, assign(socket, current_hero: updated)}
  end

  def handle_event("finish-farming", _, %{assigns: %{current_hero: %{id: id, pve_state: state} = hero}} = socket) do
    updated = Game.finish_farming!(hero)
    Game.broadcast_to_hero(id)

    {:noreply,
     assign(socket,
       current_hero: updated,
       farm_rewards: farm_rewards_for(updated, state),
       targets: Game.list_targets(updated),
       selected_turns: updated.pve_current_turns
     )}
  end

  def handle_info({"tutorial-step", %{step: step}}, socket) do
    {:noreply, assign(socket, tutorial_step: step)}
  end

  def handle_info({"hero", %{id: id}}, socket) do
    {:noreply, assign(socket, current_hero: Game.get_hero!(id))}
  end

  def handle_info(:current_time, %{assigns: %{current_hero: hero}} = socket) do
    if TrainingView.farming_progression(hero, %{current_time: Timex.now()}) < 100 do
      Process.send_after(self(), :current_time, 1000)
    end

    {:noreply, assign(socket, current_time: Timex.now())}
  end

  def handle_info(:current_time, socket), do: {:noreply, socket}

  def render(assigns) do
    MobaWeb.TrainingView.render("index.html", assigns)
  end

  defp current_farm_tab(%{pve_state: "meditating"}), do: "meditation"
  defp current_farm_tab(%{pve_state: "mining"}), do: "mine"
  defp current_farm_tab(_), do: "gank"

  defp farm_rewards_for(hero, state),
    do: Enum.filter(hero.pve_farming_rewards, &(&1.state == state)) |> Enum.sort_by(& &1.started_at, {:desc, DateTime})

  defp time_trigger, do: Process.send_after(self(), :current_time, 100)
end
