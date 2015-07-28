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
        Map.put(node_info, host_ip, parse_script_output(script_output))
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

  @doc """
  Method to parse the NodeInfo script output into a Map containing the relevant values

  ## Options 

  The `output` option defines ssh script output

  ## Return Value

  Map
  """
  @spec parse_script_output(String.t) :: Map
  def parse_script_output(output) do
    lines = String.split(output, "\n")
    {node_info, _type} = Enum.reduce lines, {%{}, nil}, fn(line, {node_info, next_line_type}) ->
      cond do
        line == "Docker Disk Space:" -> {node_info, :docker_disk_space_percent}
        line == "CoreOS Version:" -> {node_info, :coreos_version}
        line == "Docker Version:" -> {node_info, :docker_version}
        line == "Node Info commands finished successfully!" -> {node_info, nil}          
        next_line_type != nil ->
          if next_line_type == :docker_disk_space_percent do
            values = Regex.run(~r/[0-9]+%/, line)
            if values != nil && length(values) > 0 do
              line = String.replace(List.first(values), "%", "")
            end
            percent = case Integer.parse(line) do
              {percent, _} -> percent
              _ -> 0
            end
            {Map.put(node_info, next_line_type, percent), next_line_type}
          else
            info = node_info[next_line_type]
            info = "#{info}\n#{line}"
            {Map.put(node_info, next_line_type, info), next_line_type}
          end
        true -> {node_info, next_line_type}
      end
    end
    node_info
  end
end