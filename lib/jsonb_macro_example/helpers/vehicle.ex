defmodule JsonbMacroExample.Helpers.Vehicle do
  @moduledoc false

  alias JsonbMacroExample.Schemas.Vehicle

  import Ecto.Query
  import JsonbMacroExample, only: [json_multi_expressions_v2: 3]

  @type vehicle :: Ecto.Schema.t()

  def query_by_brand_capacity(brand, capacity) do
    Vehicle
    |> where([v], v.brand == ^brand)
    |> where([v], fragment("specs @> ?::jsonb", ^%{"passenger_capacity" => capacity}))
  end

  def query_by_brand_capacity_v2(brand, capacity) do
    str_capacity = to_string(capacity)

    Vehicle
    |> where([v], v.brand == ^brand)
    |> where([v], fragment("(specs ->> 'passenger_capacity') = ?", ^str_capacity))
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

  @doc """
  Builds a composable query for Vehicle's specification
  """
  @spec query_specs(Ecto.Query.t(), Keyword.t()) :: [vehicle]
  def query_specs(query, params, conjunction \\ :and) do
    fragments =
      json_multi_expressions_v2(:specs, params,
        conjunction: conjunction,
        dynamic_fun: &query_json_col/3
      )

    query
    |> where([_q], ^fragments)
  end

  # vehicle's capacity is greater or equal than `val`
  def query_json_col(col, "passenger_capacity", val) do
    dynamic([q], fragment("(?::jsonb ->> 'passenger_capacity')::int >= ?", field(q, ^col), ^val))
  end

  # no heated_seats means false, nil o inexistent `heated_seats` field
  def query_json_col(:specs, "heated_seats" = key, false) do
    dynamic(
      [q],
      fragment(
        "(specs @> ?::jsonb OR specs @> ?::jsonb OR NOT (specs \\? ?))",
        ^%{key => false},
        ^%{key => nil},
        ^key
      )
    )
  end

  def query_json_col(_, _, _), do: nil
end
