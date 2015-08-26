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
      
      {:openaperture_messaging, git: "https://github.com/OpenAperture/messaging.git", ref: "380ce611a038dd8f7afb4fa7f660aeac06475af0", override: true},
      {:openaperture_manager_api, git: "https://github.com/OpenAperture/manager_api.git", ref: "dc06f0a484410e7707dab8e96807d54a564557ed", override: true},
      {:openaperture_overseer_api, git: "https://github.com/OpenAperture/overseer_api.git", ref: "67e1ec93cf1e12e5b0e86165f33ede703a886092", override: true},
      {:openaperture_fleet, git: "https://github.com/OpenAperture/fleet.git", ref: "9fa880eef5aa23bf89e3f121df04fdc542c74c73", override: true},
      {:timex, "~> 0.13.3", override: true},
      {:fleet_api, "~> 0.0.15", override: true},
      {:poison, "~> 1.4.0", override: true},

      #test dependencies
      {:exvcr, github: "parroty/exvcr", only: :test},
      {:meck, "0.8.3", override: true},
    ]
  end
end
