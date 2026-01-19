defmodule Skwirl.Repo.Migrations.CreateProviders do
  use Ecto.Migration

  def change do
    create table(:providers, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false
      add :lua_code, :text, null: false

      timestamps(type: :utc_datetime)
    end
  end
end
