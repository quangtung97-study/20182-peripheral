defmodule Peripheral.Protocol do
  @behaviour :ranch_protocol
  use GenServer

  def start_link(ref, socket, transport, opts) do
    :proc_lib.start_link(
      __MODULE__, :init, [ref, socket, transport, opts])
  end

  def init(ref, socket, transport, _opts) do
    :ok = :proc_lib.init_ack({:ok, self()})
    :ok = :ranch.accept_ack(ref)
    :ok = transport.setopts(socket, active: :once)

    Peripheral.MCU.register(self())

    :gen_server.enter_loop(
      __MODULE__, [], {socket, transport})
  end

  def init(_args) do
    {:error, nil}
  end

  def handle_info(
    {:tcp, _socket, data}, 
    state = {socket, transport}
  ) do
    IO.inspect data
    :ok = transport.setopts(socket, active: :once)
    {:noreply, state}
  end

  def handle_info({:tcp_closed, _port}, state) do
    {:stop, :tcp_closed, state}
  end

  def handle_call(
    {:send, data}, _from, 
    state = {socket, transport}
  ) do
    IO.puts "send: #{data}"
    :ok = transport.send(socket, data)
    {:reply, :ok, state}
  end

  def send(pid, data) do
    GenServer.call(pid, {:send, data})
  end

end
