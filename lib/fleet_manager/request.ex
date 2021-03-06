defmodule OpenAperture.FleetManager.Request do
  
	@moduledoc """
	Methods and Request struct for Builder requests
	"""

  defstruct etcd_token: nil, 
  					action: nil,
	  				action_parameters: nil

  @type t :: %__MODULE__{}

  @doc """
  Method to convert a OpenAperture.FleetManager.Request struct into a map

  ## Options

  The `request` option defines the OpenAperture.FleetManager.Request

  ## Return Values

  Map
  """
  @spec to_payload(OpenAperture.FleetManager.Request.t) :: Map
  def to_payload(request) do
    Map.from_struct(request)
  end

  @doc """
  Method to convert a map into a Request struct

  ## Options

  The `payload` option defines the Map containing the request

  ## Return Values

  OpenAperture.FleetManager.Request
  """
  @spec from_payload(Map) :: OpenAperture.FleetManager.Request.t
  def from_payload(payload) do
  	%OpenAperture.FleetManager.Request{
  		etcd_token: payload[:etcd_token],
  		action: payload[:action],
      action_parameters: payload[:action_parameters],
    }
  end
end