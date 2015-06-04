defmodule OpenAperture.FleetManager.Configuration do
  
  @moduledoc "Retrieves configuration from either ENV variables or config.exs."

  @doc """
  Method to retrieve the currently assigned exchange id
   
  ## Options
   
  ## Return values

  The exchange identifier
  """ 
  @spec get_current_exchange_id() :: String.t()
  def get_current_exchange_id do
    get_config("EXCHANGE_ID", :openaperture_fleet_manager, :exchange_id)
  end

  @doc """
  Method to retrieve the currently assigned exchange id
   
  ## Options
   
  ## Return values

  The exchange identifier
  """ 
  @spec get_current_broker_id() :: String.t()
  def get_current_broker_id do
    get_config("BROKER_ID", :openaperture_fleet_manager, :broker_id)
  end

  @doc """
  Method to retrieve the currently assigned queue name (for "deployer")
   
  ## Options
   
  ## Return values

  The exchange identifier
  """ 
  @spec get_current_queue_name() :: String.t()
  def get_current_queue_name do
    get_config("QUEUE_NAME", :openaperture_fleet_manager, :queue_name)
  end

  @doc false
  # Method to retrieve a configuration option from the environment or config settings
  # 
  ## Options
  # 
  # The `env_name` option defines the environment variable name
  #
  # The `application_config` option defines the config application name (atom)
  #
  # The `config_name` option defines the config variable name (atom)
  # 
  ## Return values
  # 
  # Value
  # 
  @spec get_config(String.t(), term, term) :: String.t()
  defp get_config(env_name, application_config, config_name) do
    System.get_env(env_name) || Application.get_env(application_config, config_name)
  end  
end
