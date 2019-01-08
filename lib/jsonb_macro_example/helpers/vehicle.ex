defmodule JsonbMacroExample.Helpers.Vehicle do
  @moduledoc false

  alias JsonbMacroExample.Schemas.Vehicle

  import Ecto.Query
  import JsonbMacroExample, only: [json_multi_fragments_v1: 3]

  @type vehicle :: Ecto.Schema.t()

  def query_by_brand_capacity(brand, capacity) do
    Vehicle
    |> where([v], v.brand == ^brand)
    |> where([v], fragment("specs @> ?::jsonb", ^%{"passenger_capacity" => capacity}))
  end

  def query_by_brand_capacity_v2(brand, capacity) do
    Vehicle
    |> where([v], v.brand == ^brand)
    |> where([v], fragment("(specs -> 'passenger_capacity') = ?", ^capacity))
  end

  def query_by_engine_capacity_drive(engine, capacity, drive) do
    Vehicle
    |> where(
      [_v],
      fragment(
        "specs @> ? AND specs @> ? AND specs @> ?",
        ^%{"engine_type" => engine},
        ^%{"passenger_capacity" => capacity},
        ^%{"drive_type" => drive}
      )
    )
  end

  @spec query_specs(Ecto.Query.t(), Keyword.t()) :: [vehicle]
  def query_specs(query, params) do
    query
    |> where([q], q.brand == "Mercedez-benz")
    |> where([_q], ^json_multi_fragments_v1(:specs, params, []))
  end
end
