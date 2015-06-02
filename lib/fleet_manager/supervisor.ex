defmodule OpenAperture.FleetManager.Supervisor do

  @moduledoc "Defines the supervison tree of the application."
  
  require Logger
  use     Supervisor

  def start_link do
    Logger.info("Starting FleetManager.Supervisor...")
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    children = [
      worker(OpenAperture.FleetManager.Dispatcher, []),
      worker(OpenAperture.FleetManager.MessageManager, []),
    ]
    supervise(children, strategy: :one_for_one)
  end
end
