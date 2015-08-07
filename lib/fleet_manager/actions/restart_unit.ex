require Logger

defmodule OpenAperture.FleetManager.FleetAction.RestartUnit do

  @moduledoc """
  This module executes the following FleetManager action:  :restart_unit
  """  

  alias OpenAperture.FleetManager.Request, as: FleetRequest

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
      fleet_request.action_parameters[:host_ip] == nil -> {:error, "An invalid 'host_ip' parameter was provided!"}
      fleet_request.action_parameters[:unit_name] == nil -> {:error, "An invalid 'unit_name' parameter was provided!"}
      true -> execute_script(fleet_request.action_parameters[:host_ip], fleet_request.action_parameters[:unit_name])
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