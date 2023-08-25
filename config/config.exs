import Config

config :ex_ail,
  # api_base_url: "https://ail-project.org",
  # api_token: "YOUR_API_TOKEN",
  # api_version: "v1"
  # api_protocol: "https",
  # api_port: 7000

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
