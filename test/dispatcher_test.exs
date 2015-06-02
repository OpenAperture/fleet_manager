defmodule OpenAperture.FleetManager.DispatcherTest do
  use ExUnit.Case

  alias OpenAperture.FleetManager.Dispatcher

  alias OpenAperture.Messaging.AMQP.ConnectionPool
  alias OpenAperture.Messaging.AMQP.ConnectionPools
  alias OpenAperture.Messaging.AMQP.SubscriptionHandler
  alias OpenAperture.Messaging.ConnectionOptionsResolver
  alias OpenAperture.Messaging.AMQP.ConnectionOptions, as: AMQPConnectionOptions
  alias OpenAperture.Messaging.AMQP.QueueBuilder
  alias OpenAperture.Messaging.RpcRequest

  alias OpenAperture.FleetManager.MessageManager

  # ===================================
  # register_queues tests

  test "register_queues success" do
    :meck.new(ConnectionPools, [:passthrough])
    :meck.expect(ConnectionPools, :get_pool, fn _ -> %{} end)

    :meck.new(ConnectionPool, [:passthrough])
    :meck.expect(ConnectionPool, :subscribe, fn _, _, _, _ -> :ok end)

    :meck.new(ConnectionOptionsResolver, [:passthrough])
    :meck.expect(ConnectionOptionsResolver, :get_for_broker, fn _, _ -> %AMQPConnectionOptions{} end)

    :meck.new(QueueBuilder, [:passthrough])
    :meck.expect(QueueBuilder, :build, fn _,_,_ -> %OpenAperture.Messaging.Queue{name: ""} end)      

    assert Dispatcher.register_queues == :ok
  after
    :meck.unload(ConnectionPool)
    :meck.unload(ConnectionPools)
    :meck.unload(ConnectionOptionsResolver)
    :meck.unload(QueueBuilder)
  end

  test "register_queues failure" do
    :meck.new(ConnectionPools, [:passthrough])
    :meck.expect(ConnectionPools, :get_pool, fn _ -> %{} end)

    :meck.new(ConnectionPool, [:passthrough])
    :meck.expect(ConnectionPool, :subscribe, fn _, _, _, _ -> {:error, "bad news bears"} end)

    :meck.new(ConnectionOptionsResolver, [:passthrough])
    :meck.expect(ConnectionOptionsResolver, :get_for_broker, fn _, _ -> %AMQPConnectionOptions{} end)    

    :meck.new(QueueBuilder, [:passthrough])
    :meck.expect(QueueBuilder, :build, fn _,_,_ -> %OpenAperture.Messaging.Queue{name: ""} end)      

    assert Dispatcher.register_queues == {:error, "bad news bears"}
  after
    :meck.unload(ConnectionPool)
    :meck.unload(ConnectionPools)
    :meck.unload(ConnectionOptionsResolver)
    :meck.unload(QueueBuilder)
  end 

  test "acknowledge" do
    :meck.new(MessageManager, [:passthrough])
    :meck.expect(MessageManager, :remove, fn _ -> %{} end)

    :meck.new(SubscriptionHandler, [:passthrough])
    :meck.expect(SubscriptionHandler, :acknowledge_rpc, fn _,_,_,_ -> :ok end)

    Dispatcher.acknowledge("123abc", %RpcRequest{})
  after
    :meck.unload(MessageManager)
    :meck.unload(SubscriptionHandler)
  end

  test "reject" do
    :meck.new(MessageManager, [:passthrough])
    :meck.expect(MessageManager, :remove, fn _ -> %{} end)

    :meck.new(SubscriptionHandler, [:passthrough])
    :meck.expect(SubscriptionHandler, :reject_rpc, fn _,_,_,_,_ -> :ok end)

    Dispatcher.reject("123abc", %RpcRequest{})
  after
    :meck.unload(MessageManager)
    :meck.unload(SubscriptionHandler)
  end  
end
