use Mix.Config

# For some reason, when the nodes register themselves with etcd, they seem to
# give an incorrect port number. Manually override the port used by setting
# `fix_port_number` to true, and providing the correct port in `port_number`.
config :fleet_api, :etcd,
  fix_port_number: true,
  api_port: 7002
  
import_config "#{Mix.env}.exs"
