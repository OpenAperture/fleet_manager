defmodule OpenAperture.FleetManager.FleetActionsTest do
  use ExUnit.Case

  alias OpenAperture.FleetManager.FleetActions
  alias OpenAperture.FleetManager.Request, as: FleetRequest
  alias OpenAperture.FleetManager.FleetAction.ListMachines
  alias OpenAperture.FleetManager.FleetAction.ListUnits
  alias OpenAperture.FleetManager.FleetAction.ListUnitStates
  alias OpenAperture.FleetManager.FleetAction.UnitLogs

  # ===================================
  # execute tests

  test "execute - nil" do
    {status, response} = FleetActions.execute(%FleetRequest{})
    assert status == :error
    assert response != nil
  end

  test "execute - unknown" do
    {status, response} = FleetActions.execute(%FleetRequest{action: :foo})
    assert status == :error
    assert response != nil
  end

  test "execute - :list_machines" do
    :meck.new(ListMachines, [:passthrough])
    :meck.expect(ListMachines, :execute, fn _ -> {:ok, []} end)

    {status, response} = FleetActions.execute(%FleetRequest{action: :list_machines})
    assert status == :ok
    assert response != nil
  after
    :meck.unload(ListMachines)
  end  

  test "execute - :list_units" do
    :meck.new(ListUnits, [:passthrough])
    :meck.expect(ListUnits, :execute, fn _ -> {:ok, []} end)
    
    {status, response} = FleetActions.execute(%FleetRequest{action: :list_units})
    assert status == :ok
    assert response != nil
  after
    :meck.unload(ListUnits)
  end

  test "execute - :list_unit_states" do
    :meck.new(ListUnitStates, [:passthrough])
    :meck.expect(ListUnitStates, :execute, fn _ -> {:ok, []} end)
    
    {status, response} = FleetActions.execute(%FleetRequest{action: :list_unit_states})
    assert status == :ok
    assert response != nil
  after
    :meck.unload(ListUnitStates)
  end  

  test "execute - :unit_logs" do
    :meck.new(UnitLogs, [:passthrough])
    :meck.expect(UnitLogs, :execute, fn _ -> {:ok, []} end)
    
    {status, response} = FleetActions.execute(%FleetRequest{action: :unit_logs})
    assert status == :ok
    assert response != nil
  after
    :meck.unload(UnitLogs)
  end    
end