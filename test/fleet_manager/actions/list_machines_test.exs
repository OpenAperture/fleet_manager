defmodule OpenAperture.FleetManager.FleetAction.ListMachinesTest do
  use ExUnit.Case

  alias OpenAperture.FleetManager.Request, as: FleetRequest
  alias OpenAperture.FleetManager.FleetAction.ListMachines

  # ===================================
  # execute tests

  test "execute - start_link failed" do
  	:meck.new(FleetApi.Etcd, [:passthrough])
  	:meck.expect(FleetApi.Etcd, :start_link, fn _ -> {:error, "bad news bears"} end)

    {status, response} = ListMachines.execute(%FleetRequest{})
    assert status == :error
    assert response == "bad news bears"
  after
  	:meck.unload(FleetApi.Etcd)
  end

  test "execute - list_machines failed" do
  	:meck.new(FleetApi.Etcd, [:passthrough])
  	:meck.expect(FleetApi.Etcd, :start_link, fn _ -> {:ok, %{}} end)
  	:meck.expect(FleetApi.Etcd, :list_machines, fn _ -> {:error, "bad news bears"} end)
  	
    {status, response} = ListMachines.execute(%FleetRequest{})
    assert status == :error
    assert response == "bad news bears"
  after
  	:meck.unload(FleetApi.Etcd)
  end

  test "execute - list_machines success" do
  	:meck.new(FleetApi.Etcd, [:passthrough])
  	:meck.expect(FleetApi.Etcd, :start_link, fn _ -> {:ok, %{}} end)
  	:meck.expect(FleetApi.Etcd, :list_machines, fn _ -> {:ok, [%FleetApi.Machine{
      id: "123abc",
      metadata: nil,
      primaryIP: "127.0.0.1"}
    ]} end)
  	
    {status, response} = ListMachines.execute(%FleetRequest{})
    assert status == :ok
    assert response != nil
  after
  	:meck.unload(FleetApi.Etcd)
  end    
end