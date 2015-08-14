defmodule OpenAperture.FleetManager.Dispatcher do
  use GenServer
  
  alias OpenAperture.Messaging.AMQP.QueueBuilder
  alias OpenAperture.Messaging.AMQP.SubscriptionHandler
  alias OpenAperture.Messaging.RpcRequest

  alias OpenAperture.FleetManager.MessageManager
  alias OpenAperture.FleetManager.Configuration
  alias OpenAperture.FleetManager.Request, as: FleetRequest
  alias OpenAperture.FleetManager.FleetActions

  alias OpenAperture.ManagerApi
  alias OpenAperture.ManagerApi.SystemEvent

  @moduledoc """
  This module contains the logic to dispatch Builder messsages to the appropriate GenServer(s) 
  """  

  @connection_options nil
  use OpenAperture.Messaging  

  @doc """
  Specific start_link implementation (required by the supervisor)

  ## Options

  ## Return Values

  {:ok, pid} | {:error, reason}
  """
  @spec start_link() :: {:ok, pid} | {:error, String.t()}   
  def start_link do
    case GenServer.start_link(__MODULE__, %{}, name: __MODULE__) do
      {:error, reason} -> 
        Logger.error("[Dispatcher] Failed to start OpenAperture FleetManager:  #{inspect reason}")
        {:error, reason}
      {:ok, pid} ->
        try do
          if Application.get_env(:autostart, :register_queues, false) do
            case register_queues do
              {:ok, _} -> {:ok, pid}
              {:error, reason} -> 
                Logger.error("[Dispatcher] Failed to register FleetManager queues:  #{inspect reason}")
                {:ok, pid}
            end       
          else
            {:ok, pid}
          end
        rescue e in _ ->
          Logger.error("[Dispatcher] An error occurred registering FleetManager queues:  #{inspect e}")
          {:ok, pid}
        end
    end
  end

  @doc """
  Method to register the FleetManager queues with the Messaging system

  ## Return Value

  :ok | {:error, reason}
  """
  @spec register_queues() :: :ok | {:error, String.t()}
  def register_queues do
    Logger.debug("[Dispatcher] Registering FleetManager queues...")
    fleet_manager_queue = QueueBuilder.build(ManagerApi.get_api, Configuration.get_current_queue_name, Configuration.get_current_exchange_id)

    options = OpenAperture.Messaging.ConnectionOptionsResolver.get_for_broker(ManagerApi.get_api, Configuration.get_current_broker_id)
    subscribe(options, fleet_manager_queue, fn(payload, _meta, %{delivery_tag: delivery_tag} = async_info) -> 
      MessageManager.track(async_info)
      process_request(delivery_tag, payload)
    end)
  end

  @spec process_request_failure(String.t, String.t, RpcRequest.t) :: term
  defp process_request_failure(error_msg, delivery_tag, request) do
    Logger.error("[Dispatcher][Request][#{delivery_tag}] #{error_msg}")

    request = %{request | 
      status: :error,
      response_body: %{errors: [error_msg]}
    }        
    acknowledge(delivery_tag, request)        

    event = %{
      unique: true,
      type: :unhandled_exception, 
      severity: :error, 
      data: %{
        component: :fleet_manager,
        exchange_id: Configuration.get_current_exchange_id,
        hostname: System.get_env("HOSTNAME")
      },
      message: error_msg
    }       
    SystemEvent.create_system_event!(ManagerApi.get_api, event)    
  end

  @doc """
  Method to process FleetManager requests for a defined period of time
  
  ## Options

  The `delivery_tag` option is the unique identifier of the message

  The `payload` defines the Messaging payload

  """
  @spec process_request(String.t(), Map) :: term
  def process_request(delivery_tag, payload) do
    request = RpcRequest.from_payload(payload)

    task = Task.async(fn ->
      process_request_internal(request, delivery_tag)
    end)    

    #attempt to execute the request for 5 minutes before failing it
    try do
      Task.await(task, 300_000)
    catch
      :exit, {:timeout, task} -> process_request_failure("Request has timed out during execution!", delivery_tag, request)
      :exit, code -> process_request_failure("Exited with code #{inspect code}", delivery_tag, request)
      :throw, value -> process_request_failure("Throw called with #{inspect value}", delivery_tag, request)
      what, value -> process_request_failure("Caught #{inspect what} with #{inspect value}", delivery_tag, request)
    end  
  end

  @doc """
  Method to execute a FleetManager request
  
  ## Options

  The `request` option is the parsed RpcRequest request

  """
  @spec process_request_internal(RpcRequest.t, String.t) :: term
  def process_request_internal(request, delivery_tag) do
    try do
      Logger.debug("[Dispatcher][Request][#{delivery_tag}] Processing...")
      fleet_request = FleetRequest.from_payload(request.request_body)

      Logger.debug("[Dispatcher][Request][#{delivery_tag}] Requesting action #{inspect fleet_request.action}...")
      request = case FleetActions.execute(fleet_request) do
        {:ok, response} ->
          Logger.debug("[Dispatcher][Request][#{delivery_tag}] Completed successfully")
          %{request | 
            status: :completed,
            response_body: response,
          }
        {:error, reason} ->
          Logger.debug("[Dispatcher][Request][#{delivery_tag}] Failed:  #{inspect reason}")
          %{request | 
            status: :error,
            response_body: %{errors: ["#{inspect reason}"]},
          }
      end
      Logger.debug("[Dispatcher][Request][#{delivery_tag}] Attempting to acknowledge...")
      acknowledge(delivery_tag, request)
      Logger.debug("[Dispatcher][Request][#{delivery_tag}] Completed processing")
    catch
      :exit, code -> process_request_failure("Exited with code #{inspect code}", delivery_tag, request)
      :throw, value -> process_request_failure("Throw called with #{inspect value}", delivery_tag, request)
      what, value -> process_request_failure("Caught #{inspect what} with #{inspect value}", delivery_tag, request)           
    end
  end

  @doc """
  Method to acknowledge a message has been processed

  ## Options

  The `delivery_tag` option is the unique identifier of the message

  The `request` option is the RpcRequest

  """
  @spec acknowledge(String.t(), RpcRequest.t) :: term
  def acknowledge(delivery_tag, request) do
    message = MessageManager.remove(delivery_tag)
    unless message == nil do
      SubscriptionHandler.acknowledge_rpc(message[:subscription_handler], delivery_tag, ManagerApi.get_api, request)
      Logger.debug("[Dispatcher][Request][#{delivery_tag}] Acknowledged message...")
    else
      Logger.error("[Dispatcher][Request][#{delivery_tag}] Unable to acknowledge message, MessageManager does not have a record!")
    end
  end

  @doc """
  Method to reject a message has been processed

  ## Options

  The `delivery_tag` option is the unique identifier of the message

  The `request` option is the RpcRequest

  The `redeliver` option can be used to requeue a message
  """
  @spec reject(String.t(), RpcRequest.t, term) :: term
  def reject(delivery_tag, request, redeliver \\ false) do
    message = MessageManager.remove(delivery_tag)
    unless message == nil do
      SubscriptionHandler.reject_rpc(message[:subscription_handler], delivery_tag, ManagerApi.get_api, request, redeliver)
      Logger.debug("[Dispatcher][Request][#{delivery_tag}] Rejected message")      
    else
      Logger.error("[Dispatcher][Request][#{delivery_tag}] Unable to reject message, MessageManager does not have a record!")      
    end
  end
end