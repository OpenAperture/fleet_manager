require Logger
defmodule OpenAperture.FleetManager.FleetAction.ListUnits do

  @moduledoc """
  This module executes the following FleetManager action:  :list_units
  """  

  alias OpenAperture.FleetManager.FleetAction.FleetResponse
	alias OpenAperture.FleetManager.Request, as: FleetRequest
	alias FleetApi.Etcd, as: FleetApi

  @doc """
  Method to execute the following FleetManager action:  :list_units

  ## Options 

  The `fleet_request` option defines the incoming FleetRequest

  ## Return Value

  {:ok, response} | {:error, reason}
  """
	@spec execute(FleetRequest.t) :: {:ok, term} | {:error, String.t}
	def execute(fleet_request) do
    case FleetApi.start_link(fleet_request.etcd_token) do
    	{:ok, api_pid} -> 
        case FleetResponse.parse(FleetApi.list_units(api_pid)) do
          {:error, reason} -> {:error, reason}
          {:ok, nil} -> {:ok, nil}
          {:ok, []} -> {:ok, []}
          {:ok, raw_units} ->
            {:ok, (Enum.reduce raw_units, [], fn(unit, units) ->
              if unit != nil do
                if unit.options != nil && length(unit.options) > 0 do
                  case FleetResponse.parse({:ok, unit.options}) do
                    {:ok, options} -> unit = Map.put(unit, :options, options)
                    {:error, reason} -> Logger.error("Failed to parse unit options (#{inspect unit}):  #{inspect reason}")         
                  end
                end
                units ++ [unit]
              else
                units
              end
            end)}
        end
    	{:error, reason} -> {:error, reason}
    end
	end
end