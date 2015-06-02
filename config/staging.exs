use Mix.Config

config :autostart,
  register_queues: true
  
config :openaperture_manager_api, 
	manager_url: System.get_env("MANAGER_URL"),
	oauth_login_url: System.get_env("OAUTH_LOGIN_URL"),
	oauth_client_id: System.get_env("OAUTH_CLIENT_ID"),
	oauth_client_secret: System.get_env("OAUTH_CLIENT_SECRET")

config :openaperture_overseer_api,
	module_type: :deployer,
	exchange_id: System.get_env("EXCHANGE_ID"),
	broker_id: System.get_env("BROKER_ID")

config :fleet_api, :etcd,
  fix_port_number: true,
  api_port: 7002	