defmodule OpenAperture.FleetManager.FleetAction.UnitLogsTest do
  use ExUnit.Case

  alias OpenAperture.Fleet.SystemdUnit

  alias OpenAperture.FleetManager.Request, as: FleetRequest
  alias OpenAperture.FleetManager.FleetAction.UnitLogs

  # ===================================
  # execute tests

  test "execute - no unit name" do
    {status, response} = UnitLogs.execute(%FleetRequest{})
    assert status == :error
    assert response == "An invalid unit_name parameter was provided!"
  end

  test "execute - invalid unit name" do
    {status, response} = UnitLogs.execute(%FleetRequest{
      action_parameters: %{
        unit_name: ""
      }
      })
    assert status == :error
    assert response == "An invalid unit_name parameter was provided!"
  end

  test "execute - get_unit failed" do
  	:meck.new(SystemdUnit, [:passthrough])
  	:meck.expect(SystemdUnit, :get_unit, fn _,_ -> nil end)
  	
    {status, response} = UnitLogs.execute(%FleetRequest{
      action_parameters: %{
        unit_name: "test unit"
      }
      })
    assert status == :error
    assert response != nil
  after
  	:meck.unload(SystemdUnit)
  end

  test "execute - get_journal failed" do
    :meck.new(SystemdUnit, [:passthrough])
    :meck.expect(SystemdUnit, :get_unit, fn _,_ -> %{} end)
    :meck.expect(SystemdUnit, :get_journal, fn _ -> {:error, "stdout", "stderr"} end)
    
    {status, response} = UnitLogs.execute(%FleetRequest{
      action_parameters: %{
        unit_name: "test unit"
      }
      })
    assert status == :error
    assert response != nil
  after
    :meck.unload(SystemdUnit)
  end

  test "execute - get_journal success" do
    :meck.new(SystemdUnit, [:passthrough])
    :meck.expect(SystemdUnit, :get_unit, fn _,_ -> %{} end)
    :meck.expect(SystemdUnit, :get_journal, fn _ -> {:ok, "stdout", "stderr"} end)
    
    
    {status, response} = UnitLogs.execute(%FleetRequest{
      action_parameters: %{
        unit_name: "test unit"
      }
      })
    assert status == :ok
    assert response != nil
  after
    :meck.unload(SystemdUnit)
  end
end