defmodule OpenAperture.FleetManager.FleetActions do

  @moduledoc """
  This module executes FleetManager actions
  """  

	alias OpenAperture.FleetManager.Request, as: FleetRequest
	alias OpenAperture.FleetManager.FleetAction.ListMachines
	alias OpenAperture.FleetManager.FleetAction.ListUnits
	alias OpenAperture.FleetManager.FleetAction.ListUnitStates
	alias OpenAperture.FleetManager.FleetAction.UnitLogs
  alias OpenAperture.FleetManager.FleetAction.NodeInfo
	
  @doc """
  Method to execute FleetManager actions

  ## Options 

  The `fleet_request` option defines the incoming FleetRequest

  ## Return Value

  {:ok, response} | {:error, reason}
  """
	@spec execute(FleetRequest.t) :: {:ok, term} | {:error, String.t}
	def execute(fleet_request) do
		case fleet_request.action do
			:list_machines -> ListMachines.execute(fleet_request)
			:list_units -> ListUnits.execute(fleet_request)
			:list_unit_states -> ListUnitStates.execute(fleet_request)
			:unit_logs -> UnitLogs.execute(fleet_request)
      :node_info -> NodeInfo.execute(fleet_request)
			unknown -> {:error, "The following FleetManager action is not supported:  #{inspect unknown}"}
		end
	end
end