require Logger

defmodule OpenAperture.FleetManager.FleetAction.NodeInfo do

  @moduledoc """
  This module executes the following FleetManager action:  :node_info
  """  

  alias OpenAperture.FleetManager.Request, as: FleetRequest

  @doc """
  Method to execute the following FleetManager action:  :node_info

  ## Options 

  The `fleet_request` option defines the incoming FleetRequest

  ## Return Value

  {:ok, Map} | {:error, reason}
  """
  @spec execute(FleetRequest.t) :: {:ok, Map} | {:error, String.t}
  def execute(fleet_request) do
    if fleet_request.action_parameters[:nodes] == nil || length(fleet_request.action_parameters[:nodes]) == 0 do
      {:error, "An invalid 'nodes' parameter was provided!"}      
    else
      node_info = Enum.reduce fleet_request.action_parameters[:nodes], %{}, fn(host_ip, node_info) ->
        script_output = execute_script(host_ip)
          
        info = %{
          output:  script_output,
          docker_disk_space: nil,
          coreos_version: nil,
          docker_version: nil
        }

        Map.put(node_info, host_ip, info)
      end

      {:ok, node_info}
    end
  end

  @doc """
  Method to execute the the NodeInfo ssh script

  ## Options 

  The `host_ip` option defines ssh hostname

  ## Return Value

  Script output (string)
  """
  @spec execute_script(String.t) :: String.t
  def execute_script(host_ip) do
    script = EEx.eval_file("#{System.cwd!()}/templates/node-info.sh.eex", [host_ip: host_ip])

    path = "/tmp/node_info"
    File.mkdir_p(path)
    script_file = "#{path}/#{UUID.uuid1()}.sh"
    File.write!(script_file, script)

    resolved_cmd = "bash #{script_file} < /dev/null"

    Logger.debug ("Executing command:  #{resolved_cmd}")
    try do
      case System.cmd("/bin/bash", ["-c", resolved_cmd], []) do
        {stdout, 0} ->
          stdout
        {stdout, return_status} ->
          Logger.error("Host #{host_ip} returned an error (#{return_status}) when running the node info script:\n\n#{stdout}")
          stdout
      end
    after
      File.rm_rf(script_file)
    end
  end
end