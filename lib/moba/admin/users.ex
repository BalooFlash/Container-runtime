defmodule Moba.Admin.Users do
  @moduledoc """
  Admin functions for managing Users, mostly generated by Torch package.
  """

  alias Moba.{Repo, Accounts}
  alias Accounts.Schema.User
  alias Accounts.Query.UserQuery

  import Ecto.Query, warn: false
  import Torch.Helpers, only: [sort: 1, paginate: 4]
  import Filtrex.Type.Config

  @pagination [page_size: 50]
  @pagination_distance 5

  def paginate(params \\ %{}) do
    params =
      params
      |> Map.put_new("sort_direction", "desc")
      |> Map.put_new("sort_field", "inserted_at")

    {:ok, sort_direction} = Map.fetch(params, "sort_direction")
    {:ok, sort_field} = Map.fetch(params, "sort_field")

    with {:ok, filter} <- Filtrex.parse_params(filter_config(:users), params["user"] || %{}),
         %Scrivener.Page{} = page <- do_paginate(filter, params) do
      {:ok,
       %{
         users: page.entries,
         page_number: page.page_number,
         page_size: page.page_size,
         total_pages: page.total_pages,
         total_entries: page.total_entries,
         distance: @pagination_distance,
         sort_field: sort_field,
         sort_direction: sort_direction
       }}
    else
      {:error, error} -> {:error, error}
      error -> {:error, error}
    end
  end

  def list do
    Repo.all(User)
  end

  def get!(id), do: Repo.get!(User, id)

  def create(attrs \\ %{}) do
    %User{}
    |> User.admin_changeset(attrs)
    |> Repo.insert()
  end

  def update(%User{} = user, attrs) do
    user
    |> User.admin_changeset(attrs)
    |> Repo.update()
  end

  def delete(%User{} = user) do
    Repo.delete(user)
  end

  def change(%User{} = user) do
    User.admin_changeset(user, %{})
  end

  def get_stats do
    online_today = UserQuery.online_users(User, 24) |> UserQuery.non_guests() |> Repo.aggregate(:count)
    online_recently = UserQuery.online_users(User, 1) |> UserQuery.non_guests() |> Repo.aggregate(:count)
    new_users = UserQuery.new_users(User, 24) |> UserQuery.non_guests() |> Repo.aggregate(:count)
    new_guests = UserQuery.new_users(User, 24) |> UserQuery.guests() |> Repo.aggregate(:count)

    %{
      new_guests: new_guests,
      new_users: new_users,
      online_today: online_today,
      online_recently: online_recently
    }
  end

  defp do_paginate(filter, params) do
    User
    |> Filtrex.query(filter)
    |> order_by(^sort(params))
    |> paginate(Repo, params, @pagination)
  end

  defp filter_config(:users) do
    defconfig do
      text(:username)
      text(:email)
      boolean(:is_bot)
      boolean(:is_guest)
      boolean(:is_admin)
      number(:level)
      number(:experience)
      date(:last_online_at)
      date(:inserted_at)
    end
  end
end
