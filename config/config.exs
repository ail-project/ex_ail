import Config

config :ail,
  api_base_url: "https://ail-project.org",
  api_token: "YOUR_API_TOKEN",
  api_version: "v1"

import_config "#{config_env()}.exs"
