defmodule JsonbMacroExample.Schemas.Vehicle do
  use Ecto.Schema

  schema "vehicle" do
    field(:brand, :string)
    field(:model, :string)
    field(:specs, :map)
  end
end
