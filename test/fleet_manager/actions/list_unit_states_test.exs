defmodule OpenAperture.FleetManager.FleetAction.ListUnitStatesTest do
  use ExUnit.Case

  alias OpenAperture.FleetManager.Request, as: FleetRequest
  alias OpenAperture.FleetManager.FleetAction.ListUnitStates

  # ===================================
  # execute tests

  test "execute - start_link failed" do
  	:meck.new(FleetApi.Etcd, [:passthrough])
  	:meck.expect(FleetApi.Etcd, :start_link, fn _ -> {:error, "bad news bears"} end)

    {status, response} = ListUnitStates.execute(%FleetRequest{})
    assert status == :error
    assert response == "bad news bears"
  after
  	:meck.unload(FleetApi.Etcd)
  end

  test "execute - list_unit_states failed" do
  	:meck.new(FleetApi.Etcd, [:passthrough])
  	:meck.expect(FleetApi.Etcd, :start_link, fn _ -> {:ok, %{}} end)
  	:meck.expect(FleetApi.Etcd, :list_unit_states, fn _ -> {:error, "bad news bears"} end)
  	
    {status, response} = ListUnitStates.execute(%FleetRequest{})
    assert status == :error
    assert response == "bad news bears"
  after
  	:meck.unload(FleetApi.Etcd)
  end

  test "execute - list_unit_states success" do
  	:meck.new(FleetApi.Etcd, [:passthrough])
  	:meck.expect(FleetApi.Etcd, :start_link, fn _ -> {:ok, %{}} end)
  	:meck.expect(FleetApi.Etcd, :list_unit_states, fn _ -> {:ok, [%FleetApi.UnitState{
        hash: "eef29cad431ad16c8e164400b2f3c85afd73b238",
        machineID: "820c30c0867844129d63f4409871ba39",
        name: "subgun-http.service",
        systemdActiveState: "active",
        systemdLoadState: "loaded",
        systemdSubState: "running"}
    ]} end)
  	
    {status, response} = ListUnitStates.execute(%FleetRequest{})
    assert status == :ok
    assert response != nil
  after
  	:meck.unload(FleetApi.Etcd)
  end    
end