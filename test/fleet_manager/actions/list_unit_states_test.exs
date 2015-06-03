defmodule OpenAperture.FleetManager.FleetAction.ListUnitStatesTest do
  use ExUnit.Case

  alias FleetApi.Etcd, as: FleetApi

  alias OpenAperture.FleetManager.Request, as: FleetRequest
  alias OpenAperture.FleetManager.FleetAction.ListUnitStates

  # ===================================
  # execute tests

  test "execute - start_link failed" do
  	:meck.new(FleetApi, [:passthrough])
  	:meck.expect(FleetApi, :start_link, fn _ -> {:error, "bad news bears"} end)

    {status, response} = ListUnitStates.execute(%FleetRequest{})
    assert status == :error
    assert response == "bad news bears"
  after
  	:meck.unload(FleetApi)
  end

  test "execute - list_unit_states failed" do
  	:meck.new(FleetApi, [:passthrough])
  	:meck.expect(FleetApi, :start_link, fn _ -> {:ok, %{}} end)
  	:meck.expect(FleetApi, :list_unit_states, fn _ -> {:error, "bad news bears"} end)
  	
    {status, response} = ListUnitStates.execute(%FleetRequest{})
    assert status == :error
    assert response == "bad news bears"
  after
  	:meck.unload(FleetApi)
  end

  test "execute - list_unit_states success" do
  	:meck.new(FleetApi, [:passthrough])
  	:meck.expect(FleetApi, :start_link, fn _ -> {:ok, %{}} end)
  	:meck.expect(FleetApi, :list_unit_states, fn _ -> {:ok, %{}} end)
  	
    {status, response} = ListUnitStates.execute(%FleetRequest{})
    assert status == :ok
    assert response != nil
  after
  	:meck.unload(FleetApi)
  end    
end