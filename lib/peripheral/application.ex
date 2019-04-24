defmodule Peripheral.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Starts a worker by calling: Peripheral.Worker.start_link(arg)
      {Peripheral.MCU, []},
    ]

    opts = [strategy: :one_for_one, name: Peripheral.Supervisor]
    Supervisor.start_link(children, opts)

    {:ok, _} = :ranch.start_listener(
      :peripheral_listener,
      :ranch_tcp, [port: 5555],
      Peripheral.Protocol, [active: false]
    )
  end
end
