defmodule Skwirl.Providers.Provider do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}

  schema "providers" do
    field :name, :string
    field :lua_code, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(provider, attrs) do
    provider
    |> cast(attrs, [:name, :lua_code])
    |> validate_required([:name, :lua_code])
  end
end
