defmodule OpenAperture.FleetManager.FleetAction.NodeInfoTest do
  use ExUnit.Case

  alias OpenAperture.FleetManager.Request, as: FleetRequest
  alias OpenAperture.FleetManager.FleetAction.NodeInfo

  # ===================================
  # execute tests

  test "execute - invalid nodes" do
    {status, response} = NodeInfo.execute(%FleetRequest{})
    assert status == :error
    assert response != nil
  end   

  test "execute - no nodes" do
    {status, response} = NodeInfo.execute(%FleetRequest{
      action_parameters: %{
        nodes: []
      }
    })
    assert status == :error
    assert response != nil
  end   

  test "execute - nodes" do
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

    {status, response} = NodeInfo.execute(%FleetRequest{
      action_parameters: %{
        nodes: ["123.234.456.789", "abc.def.ghi.jkl"]
      }
    })
    assert status == :ok
    assert response != nil
    assert response["123.234.456.789"] != nil
    assert response["abc.def.ghi.jkl"] != nil
  after
    :meck.unload(File)
    :meck.unload(System)
  end  

  test "execute - node info fails" do
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

    {status, response} = NodeInfo.execute(%FleetRequest{
      action_parameters: %{
        nodes: ["123.234.456.789"]
      }
    })
    assert status == :ok
    assert response != nil
    assert response["123.234.456.789"] != nil
  after
    :meck.unload(File)
    :meck.unload(System)
  end  
end