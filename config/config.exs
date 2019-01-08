use Mix.Config

config :jsonb_macro_example, ecto_repos: [JsonbMacroExample.Repo]

import_config "#{Mix.env()}.exs"
