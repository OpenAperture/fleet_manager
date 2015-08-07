require Logger

defmodule OpenAperture.FleetManager.FleetAction.RestartUnit do

  @moduledoc """
  This module executes the following FleetManager action:  :restart_unit
  """  

  alias OpenAperture.FleetManager.Request, as: FleetRequest

  alias OpenAperture.Fleet.EtcdCluster

  @doc """
  Method to execute the following FleetManager action:  :restart_unit

  ## Options 

  The `fleet_request` option defines the incoming FleetRequest

  ## Return Value

  {:ok, Map} | {:error, reason}
  """
  @spec execute(FleetRequest.t) :: {:ok, Map} | {:error, String.t}
  def execute(fleet_request) do
    cond do
      fleet_request.action_parameters[:unit_name] == nil -> {:error, "An invalid 'unit_name' parameter was provided!"}
      true -> 
        hosts = EtcdCluster.get_hosts(fleet_request.etcd_token)
        if hosts == nil || length(hosts) == 0 do
          {:error, "Unable to find a valid host - No hosts are available in cluster #{fleet_request.etcd_token}!"}
        else
          cur_hosts_cnt = length(hosts)
          if cur_hosts_cnt == 1 do
            host = List.first(hosts)
          else
            :random.seed(:os.timestamp)
            host = List.first(Enum.shuffle(hosts))
          end

          if (host != nil && host.primaryIP != nil) do
            execute_script(host.primaryIP, fleet_request.action_parameters[:unit_name])
          else
            {:error, "Host does not have a valid primaryIP:  #{inspect host}"}
          end
        end
    end
  end

  @doc """
  Method to execute the the NodeInfo ssh script

  ## Options 

  The `host_ip` option defines ssh hostname

  The `unit_name` option defines Fleet unit to restart

  ## Return Value

  Script output (string)
  """
  @spec execute_script(String.t, String.t) :: String.t
  def execute_script(host_ip, unit_name) do
    script = EEx.eval_file("#{System.cwd!()}/templates/restart-unit.sh.eex", [host_ip: host_ip, unit_name: unit_name])

    path = "/tmp/restart_node"
    File.mkdir_p(path)
    script_file = "#{path}/#{UUID.uuid1()}.sh"
    File.write!(script_file, script)

    resolved_cmd = "bash #{script_file} < /dev/null"

    Logger.debug ("Executing command:  #{resolved_cmd}")
    try do
      case System.cmd("/bin/bash", ["-c", resolved_cmd], []) do
        {stdout, 0} -> 
          Logger.debug("Successfully restarted unit #{unit_name} via host #{host_ip}")
          {:ok, stdout}
        {stdout, return_status} ->
          Logger.error("Failed to restart unit #{unit_name} via host #{host_ip}, error code #{inspect return_status}")
          {:error, stdout}
      end
    after
      File.rm_rf(script_file)
    end
  end
end