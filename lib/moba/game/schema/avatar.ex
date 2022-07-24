defmodule Moba.Game.Schema.Avatar do
  @moduledoc """
  Represents the base stats of a Hero, and comes with a pre-defined ultimate, which is a Skill.

  Avatars are also separated by role: tank, bruiser, carry, support and nuker

  Avatars can be unlocked with shards, and may have a user level_requirement
  """
  use Ecto.Schema
  use Arc.Ecto.Schema
  import Ecto.Changeset
  alias Moba.Game

  @derive {Jason.Encoder, except: [:__meta__, :ultimate]}

  schema "avatars" do
    field :image, Moba.Image.Type
    field :background, Moba.Background.Type

    field :name, :string
    field :code, :string
    field :role, :string
    field :enabled, :boolean
    field :description, :string
    field :current, :boolean
    field :resource_uuid, :string

    field :level_requirement, :integer

    # base stats used in Hero creation
    field :atk, :integer
    field :total_hp, :integer
    field :total_mp, :integer
    field :speed, :integer
    field :power, :integer
    field :armor, :integer
    field :ultimate_code, :string

    # stat increments for when a Hero levels up
    field :atk_per_level, :integer
    field :hp_per_level, :integer
    field :mp_per_level, :integer

    belongs_to :ultimate, Game.Schema.Skill

    timestamps()
  end

  def changeset(avatar, attrs) do
    avatar
    |> cast(attrs, [
      :name,
      :code,
      :atk,
      :total_hp,
      :total_mp,
      :atk_per_level,
      :mp_per_level,
      :hp_per_level,
      :power,
      :speed,
      :armor,
      :ultimate_code,
      :role,
      :enabled,
      :level_requirement,
      :description,
      :current,
      :resource_uuid
    ])
    |> cast_attachments(attrs, [:image, :background])
  end

  def create_changeset(avatar, attrs, ultimate) do
    avatar
    |> changeset(attrs)
    |> put_assoc(:ultimate, ultimate)
  end
end
