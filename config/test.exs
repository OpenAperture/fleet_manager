use Mix.Config

config :autostart,
  register_queues: false

config :openaperture_manager_api,
  manager_url:         System.get_env("MANAGER_URL")         || "https://openaperture-mgr.host.co",
  oauth_login_url:     System.get_env("OAUTH_LOGIN_URL")     || "https://auth.host.co",
  oauth_client_id:     System.get_env("OAUTH_CLIENT_ID")     || "id",
  oauth_client_secret: System.get_env("OAUTH_CLIENT_SECRET") || "secret"

config :logger, :console,
  level: :debug

config :openaperture_overseer_api,
	module_type: :test,
	autostart: false,	
	exchange_id: "1",
	broker_id: "1"