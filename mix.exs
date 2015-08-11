defmodule OpenAperture.FleetManager.Mixfile do
  use Mix.Project

  def project do
    [app: :openaperture_fleet_manager,
     version: "0.0.1",
     elixir: "~> 1.0",
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [
      applications: [
        :logger,
        :amqp,
        :fleet_api,
        :openaperture_fleet,
        :openaperture_messaging, 
        :openaperture_manager_api, 
        :openaperture_overseer_api
      ],
      mod: {OpenAperture.FleetManager, []}
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:ex_doc, github: "elixir-lang/ex_doc", only: [:test], override: true},
      {:earmark, github: "pragdave/earmark", tag: "v0.1.8", only: [:test], override: true},    
      
      {:openaperture_messaging, git: "https://github.com/OpenAperture/messaging.git", ref: "abb5a54cabdc9c70a3d8e22558ee9c7c227c3c22", override: true},
      {:openaperture_manager_api, git: "https://github.com/OpenAperture/manager_api.git", ref: "ab5334f276b308706a91e85ca27ba937bb02fb9f", override: true},
      {:openaperture_overseer_api, git: "https://github.com/OpenAperture/overseer_api.git", ref: "25c779ea50565cdb3f783cba644294e6238ed72a", override: true},
      {:openaperture_fleet, git: "https://github.com/OpenAperture/fleet.git", ref: "0f5475c2b50a43318b6883decbaf9a472baab6c5", override: true},
      {:timex, "~> 0.12.9"},
      {:fleet_api, "~> 0.0.15", override: true},
      {:poison, "~> 1.4.0", override: true},

      #test dependencies
      {:exvcr, github: "parroty/exvcr", only: :test},
      {:meck, "0.8.2", only: :test}
    ]
  end
end
