defmodule Skwirl.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SkwirlWeb.Telemetry,
      Skwirl.Repo,
      {DNSCluster, query: Application.get_env(:skwirl, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Skwirl.PubSub},
      # Start a worker by calling: Skwirl.Worker.start_link(arg)
      # {Skwirl.Worker, arg},
      # Start to serve requests, typically the last entry
      SkwirlWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Skwirl.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SkwirlWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
