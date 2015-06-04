defmodule OpenAperture.FleetManager.FleetAction.ListUnitsTest do
  use ExUnit.Case

  alias OpenAperture.FleetManager.Request, as: FleetRequest
  alias OpenAperture.FleetManager.FleetAction.ListUnits

  # ===================================
  # execute tests

  test "execute - start_link failed" do
  	:meck.new(FleetApi.Etcd, [:passthrough])
  	:meck.expect(FleetApi.Etcd, :start_link, fn _ -> {:error, "bad news bears"} end)

    {status, response} = ListUnits.execute(%FleetRequest{})
    assert status == :error
    assert response == "bad news bears"
  after
  	:meck.unload(FleetApi.Etcd)
  end

  test "execute - list_units failed" do
  	:meck.new(FleetApi.Etcd, [:passthrough])
  	:meck.expect(FleetApi.Etcd, :start_link, fn _ -> {:ok, %{}} end)
  	:meck.expect(FleetApi.Etcd, :list_units, fn _ -> {:error, "bad news bears"} end)
  	
    {status, response} = ListUnits.execute(%FleetRequest{})
    assert status == :error
    assert response == "bad news bears"
  after
  	:meck.unload(FleetApi.Etcd)
  end

  test "execute - list_units success" do
  	:meck.new(FleetApi.Etcd, [:passthrough])
  	:meck.expect(FleetApi.Etcd, :start_link, fn _ -> {:ok, %{}} end)
  	:meck.expect(FleetApi.Etcd, :list_units, fn _ -> {:ok, [%FleetApi.Unit{
      name: "test.service",
      desiredState: "launched",
      options: [
        %FleetApi.UnitOption{
          name: "ExecStart",
          section: "Service",
          value: "/usr/bin/sleep 3000"
        }
      ]

    }]} end)
  	
    {status, response} = ListUnits.execute(%FleetRequest{})
    assert status == :ok
    assert response != nil
  after
  	:meck.unload(FleetApi.Etcd)
  end    
end