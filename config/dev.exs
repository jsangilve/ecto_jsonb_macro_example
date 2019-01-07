use Mix.Config

config :jsonb_macro_example, ecto_repos: [JsonbMacroExample.Repo]

config :jsonb_macro_example, JsonbMacroExample.Repo,
  database: "jsonb_macro_example",
  username: "oss",
  password: "opensource",
  hostname: "localhost",
  port: "5432"
