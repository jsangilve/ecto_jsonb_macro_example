defmodule JsonbMacroExample.Repo do
  use Ecto.Repo,
    otp_app: :jsonb_macro_example,
    adapter: Ecto.Adapters.Postgres
end
