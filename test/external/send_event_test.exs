require Logger

defmodule OpenAperture.FleetManager.TestPublisher do

  alias OpenAperture.Messaging.ConnectionOptionsResolver
	alias OpenAperture.Messaging.AMQP.QueueBuilder

	alias OpenAperture.ManagerApi
	alias OpenAperture.Messaging.RpcRequest
	alias OpenAperture.Messaging.AMQP.RpcHandler

	alias OpenAperture.FleetManager.Configuration
	alias OpenAperture.FleetManager.Request, as: FleetRequest

	@connection_options nil
	use OpenAperture.Messaging

	def get_hosts(etcd_token, messaging_exchange_id) do
    fleet_manager_queue = QueueBuilder.build(ManagerApi.get_api, "fleet_manager", messaging_exchange_id)

    connection_options = ConnectionOptionsResolver.resolve(
      ManagerApi.get_api, 
      Configuration.get_current_broker_id,
      Configuration.get_current_exchange_id,
      messaging_exchange_id
    )

    request = %RpcRequest{
    	status: :in_progress,
    	request_body: FleetRequest.to_payload(%FleetRequest{
    		etcd_token: etcd_token,
    		action: :list_machines
    	})
    }
		case publish_rpc(connection_options, fleet_manager_queue, ManagerApi.get_api, request) do
			{:error, reason} -> {:error, reason}
			{:ok, handler} -> RpcHandler.get_response(handler)
		end
	end
end

defmodule OpenAperture.FleetManager.PublishTest do
  use ExUnit.Case
  @moduletag :external

  alias OpenAperture.FleetManager.TestPublisher

  test "get_hosts" do
  	OpenAperture.Messaging.AMQP.ConnectionPools.start_link

  	case TestPublisher.get_hosts("123abc", 1) do
			{:ok, hosts} -> 
				Logger.info("Received the following hosts:  #{inspect hosts}")
			{:error, reason} -> 
				Logger.error("Received the following error retrieving hosts:  #{inspect reason}")
				{:error, reason}
  	end
  end
end
