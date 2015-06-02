defmodule OpenAperture.FleetManager do

  @moduledoc "Defines the FleetManager application."

  require Logger
  use     Application

  @doc """
  Starts the application.

  Returns `:ok` or `{:error, explanation}` otherwise.
  """
  @spec start(:atom, [any]) :: :ok | {:error, String.t}
  def start(_type, _args) do
    Logger.info("Starting FleetManager...")
    OpenAperture.FleetManager.Supervisor.start_link
  end
end
