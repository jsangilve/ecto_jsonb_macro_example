defmodule JsonbMacroExample do
  @moduledoc """
  Examples of a macro to query over multiple attributes of a JSONB column
  """

  import Ecto.Query

  #########
  # Macros

  @doc """
  A macro that transforms parameter into `where` / `or_where` expressions
  over the `jsonb` column `col`.
  """
  defmacro json_where_query(query, col, params, opts) do
    where_type = Keyword.get(opts, :where_type, :where)

    quote do
      Enum.reduce(unquote(params), unquote(query), fn {key, val}, acc ->
        from(q in acc, [
          {
            unquote(where_type),
            fragment(
              "?::jsonb @> ?::jsonb",
              field(q, ^unquote(col)),
              ^%{to_string(key) => val}
            )
          }
        ])
      end)
    end
  end

  @doc """
  v0: A macro that generates multiple fragments using dynamic expressions.
  """
  defmacro json_multi_fragments_v0(col, params, opts) do
    conjunction = Keyword.get(opts, :conjunction, :and)
    # conjuctive operator to be used between fragments

    quote do
      fragments =
        Enum.reduce(unquote(params), nil, fn {key, val}, acc ->
          frag =
            dynamic(
              [q],
              fragment(
                "?::jsonb @> ?::jsonb",
                field(q, ^unquote(col)),
                ^%{to_string(key) => val}
              )
            )

          JsonbMacroExample.do_combine(frag, acc, unquote(conjunction))
        end)
    end
  end

  @doc """
  v1: A macro that generates multiple fragments using dynamic expressions.
  """
  defmacro json_multi_fragments_v1(col, params, opts) do
    conjunction = Keyword.get(opts, :conjunction, :and)
    # conjuctive operator to be used between fragments

    quote do
      fragments =
        Enum.reduce(unquote(params), nil, fn {key, val}, acc ->
          JsonbMacroExample.combine_fragments(unquote(col), key, val, acc, unquote(conjunction))
        end)
    end
  end

  @doc false
  @spec combine_fragments(atom(), binary() | atom(), term(), Macro.t(), atom()) :: Macro.t()
  def combine_fragments(col, key, val, acc, conjunction) do
    frag =
      dynamic(
        [q],
        fragment(
          "?::jsonb @> ?::jsonb",
          field(q, ^col),
          ^%{to_string(key) => val}
        )
      )

    # TODO I'd write this using a case, but it generates a compilation warning
    # https://github.com/elixir-lang/elixir/issues/6738
    JsonbMacroExample.do_combine(frag, acc, conjunction)
  end

  @doc false
  def do_combine(frag, acc, conjunction)
  def do_combine(frag, nil, _), do: frag
  def do_combine(frag, acc, :or), do: dynamic([q], ^acc or ^frag)
  def do_combine(frag, acc, _), do: dynamic([q], ^acc and ^frag)

  @doc """
  Creates an `OR` query expression over a JSONB column given multiple attributes and values.

  This macro will use the `@>` operator to check for each key and value by default.
  """
  defmacro jsonb_or_where(query, col, params, opts \\ []),
    do: do_json_where_macro(query, col, params, [{:where_type, :or_where} | opts])

  @doc """
  Create an `AND` query over a JSONB column given multiple attributes and values.

  By default, this macro will use the `@>` operator to check for each key and value
  provided in `params`.

  ## Options

    * `gen_dynamic` - An optional function to generate a dynamic fragment
    (using `Ecto.Query.dynamic`).

  ## Examples

  ```
  iex> alias BitcloudDB.Schemas.Server
  iex> from(s in Server, where: not is_nil(s.data)) |> jsonb_and_where(:data, disallowed: true, manufacturer: nil)
  Ecto.Query<from s in BitcloudDB.Schemas.Server, where: not(is_nil(s.data)),
  where: fragment("?::jsonb @> ?::jsonb", s.data, ^%{disallowed: true}),
  where: fragment("?::jsonb @> ?::jsonb", s.data, ^%{manufacturer: nil})>
  ```
  """
  defmacro jsonb_and_where(query, col, params, opts \\ []),
    do: do_json_where_macro(query, col, params, [{:where_type, :where} | opts])

  defp do_json_where_macro(query, _, [], _), do: query

  defp do_json_where_macro(query, col, params, opts) do
    where_type = Keyword.get(opts, :where_type, :where)
    dynamic_fun = Keyword.get(opts, :gen_dynamic)

    quote do
      dynamic_fun = unquote(dynamic_fun)

      Enum.reduce(unquote(params), unquote(query), fn {key, val}, acc ->
        key = to_string(key)

        # either use dynamic_func to create the dynamic fragment or use
        # the default one
        frag =
          if dynamic_fun do
            dynamic_fun.(unquote(col), key, val)
          else
            dynamic(
              [q],
              fragment(
                "?::jsonb @> ?::jsonb",
                field(q, ^unquote(col)),
                ^%{key => val}
              )
            )
          end

        from(q in acc, [
          {
            unquote(where_type),
            ^frag
          }
        ])
      end)
    end
  end
end
