# OpenAperture.FleetManager
 
[![Build Status](https://semaphoreci.com/api/v1/projects/715c63e3-718c-4e95-9d8c-81ee27e1ede9/443243/badge.svg)](https://semaphoreci.com/perceptive/fleet_manager) 
 
The FleetManager module provides a standardized mechanism to execute Fleet commands to EtcdClusters through the OpenAperture system.

## Module Responsibilities

The FleetManager module is responsible for the following actions within OpenAperture:

* Retrieving a list of Machines from a remote Cluster
* Retrieving a list of Units from a remote Cluster
* Retrieving a list of Unit States from a remote Cluster
* Retrieving Unit Logs from a remote Cluster

## Messaging / Communication

The following RPC message(s) may be sent to the FleetManager:

* Request a Fleet Action
	* Queue:  fleet_manager
	* Payload (Map)
		* 
      %{
        status: <atom>,
        request_body: %{
          etcd_token: <etcd_token>,
          action: :list_machines | :list_units | :list_unit_states | :unit_logs
        }
      }

## Module Configuration

The following configuration values must be defined either as environment variables or as part of the environment configuration files:

* Current Exchange
	* Type:  String
	* Description:  The identifier of the exchange in which the FleetManager is running
  * Environment Variable:  EXCHANGE_ID
* Current Broker
	* Type:  String
	* Description:  The identifier of the broker to which the FleetManager is connecting
  * Environment Variable:  BROKER_ID
* Manager URL
  * Type: String
  * Description: The url of the OpenAperture Manager
  * Environment Variable:  MANAGER_URL
  * Environment Configuration (.exs): :openaperture_manager_api, :manager_url
* OAuth Login URL
  * Type: String
  * Description: The login url of the OAuth2 server
  * Environment Variable:  OAUTH_LOGIN_URL
  * Environment Configuration (.exs): :openaperture_manager_api, :oauth_login_url
* OAuth Client ID
  * Type: String
  * Description: The OAuth2 client id to be used for authenticating with the OpenAperture Manager
  * Environment Variable:  OAUTH_CLIENT_ID
  * Environment Configuration (.exs): :openaperture_manager_api, :oauth_client_id
* OAuth Client Secret
  * Type: String
  * Description: The OAuth2 client secret to be used for authenticating with the OpenAperture Manager
  * Environment Variable:  OAUTH_CLIENT_SECRET
  * Environment Configuration (.exs): :openaperture_manager_api, :oauth_client_secret
* System Module Type
	* Type:  atom or string
	* Description:  An atom or string describing what kind of system module is running (i.e. builder, deployer, etc...)
  * Environment Configuration (.exs): :openaperture_overseer_api, :module_type

## Building & Testing

### Building

The normal elixir project setup steps are required:

```iex
mix do deps.get, deps.compile
```

To startup the application, use mix run:

```iex
MIX_ENV=prod elixir --sname fleet_manager -S mix run --no-halt
```

### Testing 

You can then run the tests

```iex
MIX_ENV=test mix test test/
```