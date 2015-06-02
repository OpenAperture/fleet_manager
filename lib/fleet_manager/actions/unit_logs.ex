defmodule OpenAperture.FleetManager.FleetAction.UnitLogs do

  @moduledoc """
  This module executes the following FleetManager action:  :list_units
  """  

	alias OpenAperture.FleetManager.Request, as: FleetRequest
  alias OpenAperture.Fleet.SystemdUnit

  @doc """
  Method to execute the following FleetManager action:  :list_units

  ## Options 

  The `fleet_request` option defines the incoming FleetRequest

  ## Return Value

  {:ok, response} | {:error, reason}
  """
	@spec execute(FleetRequest.t) :: {:ok, term} | {:error, String.t}
	def execute(fleet_request) do
    if fleet_request.action_parameters[:unit_name] == nil || String.length(fleet_request.action_parameters[:unit_name]) == 0 do
      {:error, "An invalid unit_name parameter was provided!"}      
    else
      unit = SystemdUnit.get_unit(fleet_request.action_parameters[:unit_name], fleet_request.etcd_token)
      if unit == nil do
        {:error, "Unable to load unit #{fleet_request.action_parameters[:unit_name]} on cluster #{fleet_request.etcd_token}!"}      
      else
        case SystemdUnit.get_journal(unit) do
          {:ok, stdout, stderr} -> {:ok, "#{stdout}\n\n#{stderr}"}
          {:error, stdout, stderr} -> {:error, "Failed to retrieve logs for unit #{fleet_request.action_parameters[:unit_name]} on cluster #{fleet_request.etcd_token}!\n\n#{stdout}\n\n#{stderr}"}
        end
      end
    end
	end
end