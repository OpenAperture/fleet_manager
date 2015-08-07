defmodule OpenAperture.FleetManager.FleetAction.RestartUnitTest do
  use ExUnit.Case

  alias OpenAperture.FleetManager.Request, as: FleetRequest
  alias OpenAperture.FleetManager.FleetAction.RestartUnit

  alias OpenAperture.Fleet.EtcdCluster

  # ===================================
  # execute tests

  test "execute - no unit_name" do
    {status, response} = RestartUnit.execute(%FleetRequest{
      action_parameters: %{
        host_ip: "123.234.456.789"
      }
    })
    assert status == :error
    assert response != nil
  end   

  test "execute - no hosts available" do
    :meck.new(EtcdCluster, [:passthrough])
    :meck.expect(EtcdCluster, :get_hosts, fn _ -> [] end)

    {status, response} = RestartUnit.execute(%FleetRequest{
      action_parameters: %{
        unit_name: "test@.service"
      }
    })
    assert status == :error
    assert response != nil
  after
    :meck.unload(EtcdCluster)
  end  

  test "execute - success" do
    :meck.new(EtcdCluster, [:passthrough])
    :meck.expect(EtcdCluster, :get_hosts, fn _ -> [%FleetApi.Machine{primaryIP: "123.234.456.789"}, %FleetApi.Machine{primaryIP: "234.456.789.123"}] end)

    template = File.read!("#{System.cwd!()}/templates/node-info.sh.eex")

    :meck.new(File, [:unstick])
    :meck.expect(File, :mkdir_p, fn _path -> true end)
    :meck.expect(File, :write!, fn _path, _content -> true end)
    :meck.expect(File, :read!, fn _path -> template end)
    :meck.expect(File, :rm_rf, fn _path -> true end)

    cwd = System.cwd!
    :meck.new(System, [:unstick])
    :meck.expect(System, :cwd!, fn -> cwd end)
    :meck.expect(System, :cmd, fn command, args, _opts ->
      assert command == "/bin/bash" || command == "cmd.exe"
      assert String.contains?(Enum.at(args, 1), "bash ")
      {"script output", 0}
    end)
    :meck.expect(System, :user_home, fn -> "/" end)

    {status, response} = RestartUnit.execute(%FleetRequest{
      action_parameters: %{
        host_ip: "123.234.456.789",
        unit_name: "test@.service"
      }
    })
    assert status == :ok
    assert response != nil
  after
    :meck.unload(EtcdCluster)
    :meck.unload(File)
    :meck.unload(System)
  end  

  test "execute - fails" do
    :meck.new(EtcdCluster, [:passthrough])
    :meck.expect(EtcdCluster, :get_hosts, fn _ -> [%FleetApi.Machine{primaryIP: "123.234.456.789"}, %FleetApi.Machine{primaryIP: "234.456.789.123"}] end)

    template = File.read!("#{System.cwd!()}/templates/node-info.sh.eex")

    :meck.new(File, [:unstick])
    :meck.expect(File, :mkdir_p, fn _path -> true end)
    :meck.expect(File, :write!, fn _path, _content -> true end)
    :meck.expect(File, :read!, fn _path -> template end)
    :meck.expect(File, :rm_rf, fn _path -> true end)

    cwd = System.cwd!
    :meck.new(System, [:unstick])
    :meck.expect(System, :cwd!, fn -> cwd end)
    :meck.expect(System, :cmd, fn command, args, _opts ->
      assert command == "/bin/bash" || command == "cmd.exe"
      assert String.contains?(Enum.at(args, 1), "bash ")
      {"script output", 123}
    end)
    :meck.expect(System, :user_home, fn -> "/" end)

    {status, response} = RestartUnit.execute(%FleetRequest{
      action_parameters: %{
        host_ip: "123.234.456.789",
        unit_name: "test@.service"
      }
    })
    assert status == :error
    assert response != nil
  after
    :meck.unload(EtcdCluster)
    :meck.unload(File)
    :meck.unload(System)
  end 
end