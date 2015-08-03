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

  # ================================ 
  # parse_script_output tests

  test "parse_script_output properly formatted" do
    output = "Prepping SSH keys...\nAgent pid 92\nDocker Disk Space:\n/dev/xvdd          50269  6003     41691  13% /var/lib/docker\nCoreOS Version:\nNAME=CoreOS\nID=coreos\nVERSION=717.3.0\nVERSION_ID=717.3.0\nBUILD_ID=\nPRETTY_NAME=\"CoreOS 717.3.0\"\nANSI_COLOR=\"1;32\"\nHOME_URL=\"https://coreos.com/\"\nBUG_REPORT_URL=\"https://github.com/coreos/bugs/issues\"\nDocker Version:\nClient version: 1.6.2\nClient API version: 1.18\nGo version (client): go1.4.2\\\nGit commit (client): 7c8fca2-dirty\nOS/Arch (client): linux/amd64\nServer version: 1.6.2\nServer API version: 1.18\nGo version (server): go1.4.2\nGit commit (server): 7c8fca2-dirty\nOS/Arch (server): linux/amd64\nNode Info commands finished successfully!\nunset SSH_AUTH_SOCK;\nunset SSH_AGENT_PID;\necho Agent pid 92 killed;\n"
    node_info = NodeInfo.parse_script_output(output)
    assert node_info != nil
    assert node_info[:coreos_version] == "\nNAME=CoreOS\nID=coreos\nVERSION=717.3.0\nVERSION_ID=717.3.0\nBUILD_ID=\nPRETTY_NAME=\"CoreOS 717.3.0\"\nANSI_COLOR=\"1;32\"\nHOME_URL=\"https://coreos.com/\"\nBUG_REPORT_URL=\"https://github.com/coreos/bugs/issues\""
    assert node_info[:docker_disk_space_percent] == 13
    assert node_info[:docker_version] == "\nClient version: 1.6.2\nClient API version: 1.18\nGo version (client): go1.4.2\\\nGit commit (client): 7c8fca2-dirty\nOS/Arch (client): linux/amd64\nServer version: 1.6.2\nServer API version: 1.18\nGo version (server): go1.4.2\nGit commit (server): 7c8fca2-dirty\nOS/Arch (server): linux/amd64"
  end

  test "parse_script_output empty output" do
    output = ""
    node_info = NodeInfo.parse_script_output(output)
    assert node_info != nil
    assert node_info[:coreos_version] == nil
    assert node_info[:docker_disk_space_percent] == nil
    assert node_info[:docker_version] == nil
  end

  test "parse_script_output bad output" do
    output = "Prepping SSH keys...\nAgent pid 92\nDocker Disk Space:\n/dev/xvdd  /var/lib/docker\nCoreOS Version:\nNAME=CoreOS\nID=cAME=\"CoreOS 717.3.0\"\nANSI_COLOR=\"1;32\"\nHOME_URL=\"https://coreos.com/\"\nBUG_REPORT_URL=\"https://github.com/coreos/bugs/issues\"\nDocker Version:\nClient version: 1.6.2\nClient API version: 1.18\nGo version (client): go1.4.2\\\nGit commit (client): 7c8fca2-dirty\nOS/Arch (client): linux/amd64\nServer version: 1.6.2\nServer API version: 1.18\nGo version (server): go1.4.2\nGit comArch (server): linux/amd64\nNode Info commands finished successfully!\nunset SSH_AUTH_SOCK;\nunset SSH_AGENT_PID;\necho Agent pid 92 killed;\n"
    node_info = NodeInfo.parse_script_output(output)
    assert node_info != nil
    assert node_info[:coreos_version] != nil
    assert node_info[:docker_disk_space_percent] == 0
    assert node_info[:docker_version] != nil
  end
end