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

  @doc """
  Method to process FleetManager requests
  
  ## Options

  The `delivery_tag` option is the unique identifier of the message

  The `payload` defines the Messaging payload

  """
  @spec process_request(String.t(), Map) :: term
  def process_request(delivery_tag, payload) do
    request = RpcRequest.from_payload(payload)
    try do
      Logger.debug("[Dispatcher] Starting to process request #{delivery_tag}...")
      fleet_request = FleetRequest.from_payload(request.request_body)

      request = case FleetActions.execute(fleet_request) do
        {:ok, response} ->
          Logger.debug("[Dispatcher] Request #{delivery_tag} responded successfully:  #{inspect response}")
          %{request | 
            status: :completed,
            response_body: response,
          }
        {:error, reason} ->
          Logger.debug("[Dispatcher] Request #{delivery_tag} responded failed:  #{inspect reason}")
          %{request | 
            status: :error,
            response_body: %{errors: ["#{inspect reason}"]},
          }
      end
      acknowledge(delivery_tag, request)
    catch
      :exit, code   -> 
        error_msg = "[Dispatcher] Message #{delivery_tag} Exited with code #{inspect code}"
        Logger.error(error_msg)
        request = %{request | 
          status: :error,
          response_body: %{errors: [error_msg]}
        }
        event = %{
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
        acknowledge(delivery_tag, request)
      :throw, value -> 
        error_msg = "[Dispatcher] Message #{delivery_tag} Throw called with #{inspect value}"
        Logger.error(error_msg)
        request = %{request | 
          status: :error,
          response_body: %{errors: [error_msg]}
        }
        event = %{
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
        acknowledge(delivery_tag, request)
      what, value   -> 
        error_msg = "[Dispatcher] Message #{delivery_tag} Caught #{inspect what} with #{inspect value}"
        Logger.error(error_msg)
        request = %{request | 
          status: :error,
          response_body: %{errors: [error_msg]}
        }      
        event = %{
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
        acknowledge(delivery_tag, request)
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
      Logger.debug("[Dispatcher] Acknowledging message #{delivery_tag}...")
      SubscriptionHandler.acknowledge_rpc(message[:subscription_handler], delivery_tag, ManagerApi.get_api, request)
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
      Logger.debug("[Dispatcher] Rejecting message #{delivery_tag}...")
      SubscriptionHandler.reject_rpc(message[:subscription_handler], delivery_tag, ManagerApi.get_api, request, redeliver)
    end
  end
end