defmodule MobaWeb.Tutorial do
  use MobaWeb, :live_component

  @final_training_step 19
  @final_base_step 29
  @final_arena_step 39

  def mount(socket) do
    {:ok, socket}
  end

  def render(assigns) do
    MobaWeb.GameView.render("tutorial.html", assigns)
  end

  def subscribe(user_id) do
    MobaWeb.subscribe("tutorial-#{user_id}")
    user_id
  end

  def next_step(%{assigns: %{tutorial_step: current_step}} = socket, step)
      when current_step == step - 1 do
    set_step(socket, step)
  end

  def next_step(socket, _), do: socket

  def set_step(%{assigns: %{current_hero: hero}} = socket, step) when not is_nil(hero) do
    Moba.Accounts.update_tutorial_step!(hero.user, step)

    MobaWeb.broadcast("tutorial-#{hero.user_id}", "tutorial-step", %{step: step})

    assign(socket, tutorial_step: step)
  end

  def set_step(socket, _), do: socket

  def finish_training(socket), do: set_step(socket, @final_training_step)
  def finish_base(socket), do: set_step(socket, @final_base_step)
  def finish_arena(socket), do: set_step(socket, @final_arena_step)
end
