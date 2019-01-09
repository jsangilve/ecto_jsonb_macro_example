defmodule JsonbMacroExample do
  @moduledoc """
  Examples of a macro to query over multiple attributes of a JSONB column
  """

  import Ecto.Query

  ###########
  ## Macros
  ###########

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

  ###########
  ## Macro v0

  @doc """
  v0: A macro that generates multiple fragments using dynamic expressions.
  """
  defmacro json_multi_expressions_v0(col, params, opts) do
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

  ###########
  ## Macro v1

  @doc """
  v1: A macro that generates multiple fragments using dynamic expressions.

  ## Options

    * `conjunction`: define whether to use `and` or `or` to join dynamic expressions
    for each parameter. By default uses `and`.
  """
  defmacro json_multi_expressions_v1(col, params, opts) do
    # conjuctive operator to be used between fragments
    conjunction = Keyword.get(opts, :conjunction, :and)

    quote do
      JsonbMacroExample.build_fragments(
        unquote(params),
        unquote(col),
        unquote(conjunction)
      )
    end
  end

  ##################
  ## The Final Macro

  @doc """
  v2: A macro that generates multiple fragments using dynamic expressions.

  ## Options

    * `conjunction`: define whether to use `and` or `or` to join dynamic expressions
    for each parameter. By default uses `and`.
    * `gen_dynamic` - An optional function to generate a dynamic fragment
    (using `Ecto.Query.dynamic`).
  """
  defmacro json_multi_expressions(col, params, opts) do
    # conjuctive operator to be used between fragments
    conjunction = Keyword.get(opts, :conjunction, :and)
    # a function that generates a dynamic expression
    dynamic_fun = Keyword.get(opts, :dynamic_fun)

    quote do
      JsonbMacroExample.build_expressions(
        unquote(params),
        unquote(col),
        unquote(conjunction),
        unquote(dynamic_fun)
      )
    end
  end

  #########
  # Helpers

  @doc false
  @spec build_fragments(map() | Keyword.t(), atom(), atom()) :: Macro.t()
  def build_fragments(params, col, conjunction) do
    Enum.reduce(params, nil, fn {key, val}, acc ->
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
    end)
  end

  @doc false
  def do_combine(frag, acc, conjunction)
  def do_combine(frag, nil, _), do: frag
  def do_combine(frag, acc, :or), do: dynamic([q], ^acc or ^frag)
  def do_combine(frag, acc, _), do: dynamic([q], ^acc and ^frag)

  @doc false
  @spec build_expressions(map() | Keyword.t(), atom(), atom(), fun()) :: Macro.t()
  def build_expressions(params, col, conjunction, dynamic_fun \\ nil)

  def build_expressions(params, col, conjunction, dynamic_fun) do
    Enum.reduce(params, nil, fn {key, val}, acc ->
      frag = JsonbMacroExample.build_fragment(col, to_string(key), val, dynamic_fun)

      # TODO I'd write this using a case, but it generates a compilation warning
      # https://github.com/elixir-lang/elixir/issues/6738
      JsonbMacroExample.do_combine(frag, acc, conjunction)
    end)
  end

  @doc false
  @spec build_fragment(binary(), atom | binary(), term(), fun()) :: Macro.t()
  def build_fragment(col, key, val, nil) do
    # build default dynamic fragment
    dynamic(
      [q],
      fragment(
        "?::jsonb @> ?::jsonb",
        field(q, ^col),
        ^%{key => val}
      )
    )
  end

  def build_fragment(col, key, val, dynamic_fun) do
    result = dynamic_fun.(col, key, val)

    case result do
      nil ->
        build_fragment(col, key, val, nil)

      _ ->
        result
    end
  end
end
