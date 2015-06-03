defmodule OpenAperture.FleetManager.FleetAction.ListMachinesTest do
  use ExUnit.Case

  alias FleetApi.Etcd, as: FleetApi

  alias OpenAperture.FleetManager.Request, as: FleetRequest
  alias OpenAperture.FleetManager.FleetAction.ListMachines

  # ===================================
  # execute tests

  test "execute - start_link failed" do
  	:meck.new(FleetApi, [:passthrough])
  	:meck.expect(FleetApi, :start_link, fn _ -> {:error, "bad news bears"} end)

    {status, response} = ListMachines.execute(%FleetRequest{})
    assert status == :error
    assert response == "bad news bears"
  after
  	:meck.unload(FleetApi)
  end

  test "execute - list_machines failed" do
  	:meck.new(FleetApi, [:passthrough])
  	:meck.expect(FleetApi, :start_link, fn _ -> {:ok, %{}} end)
  	:meck.expect(FleetApi, :list_machines, fn _ -> {:error, "bad news bears"} end)
  	
    {status, response} = ListMachines.execute(%FleetRequest{})
    assert status == :error
    assert response == "bad news bears"
  after
  	:meck.unload(FleetApi)
  end

  test "execute - list_machines success" do
  	:meck.new(FleetApi, [:passthrough])
  	:meck.expect(FleetApi, :start_link, fn _ -> {:ok, %{}} end)
  	:meck.expect(FleetApi, :list_machines, fn _ -> {:ok, %{}} end)
  	
    {status, response} = ListMachines.execute(%FleetRequest{})
    assert status == :ok
    assert response != nil
  after
  	:meck.unload(FleetApi)
  end    
end