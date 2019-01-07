defmodule JsonbMacroExample.Repo.Migrations.AddVehicleTable do
  use Ecto.Migration

  def change do
    create table("vehicle") do
      add :brand, :string, null: false
      add :model, :string, null: false
      add :specs, :jsonb
    end
  end
end
