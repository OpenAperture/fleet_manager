defmodule OpenAperture.FleetManager.FleetAction.ListMachines do

  @moduledoc """
  This module executes the following FleetManager action:  :list_machines
  """  

  alias OpenAperture.FleetManager.FleetAction.FleetResponse
	alias OpenAperture.FleetManager.Request, as: FleetRequest
	alias FleetApi.Etcd, as: FleetApi

  @doc """
  Method to execute the following FleetManager action:  :list_machines

  ## Options 

  The `fleet_request` option defines the incoming FleetRequest

  ## Return Value

  {:ok, list} | {:error, reason}
  """
	@spec execute(FleetRequest.t) :: {:ok, list} | {:error, String.t}
	def execute(fleet_request) do
    case FleetApi.start_link(fleet_request.etcd_token) do
      {:ok, api_pid}   -> FleetResponse.parse(FleetApi.list_machines(api_pid))
      {:error, reason} -> {:error, reason}
    end
  end
end
