defmodule Peripheral.Protocol do
  @behaviour :ranch_protocol
  use GenServer

  alias Peripheral.MCUWorker

  def start_link(ref, socket, transport, opts) do
    :proc_lib.start_link(
      __MODULE__, :init, [ref, socket, transport, opts])
  end

  def init(ref, socket, transport, _opts) do
    :ok = :proc_lib.init_ack({:ok, self()})
    :ok = :ranch.accept_ack(ref)
    :ok = transport.setopts(socket, active: :once)

    MCUWorker.register(self())

    :gen_server.enter_loop(
      __MODULE__, [], {socket, transport})
  end

  def init(_args) do
    {:error, nil}
  end

  defp processing_data(data, transport, socket) do
    <<size, content :: binary>> = data
    content_size = byte_size(content)
    cond do
      size > content_size ->
        {:ok, remain} = transport.recv(socket, size - content_size, 5000)
        MCUWorker.msg(content <> remain)

      size == content_size ->
        MCUWorker.msg(content)

      true ->
        MCUWorker.msg(binary_part(content, 0, size))
        data = binary_part(content, size, content_size - size)
        processing_data(data, transport, socket)
    end
  end

  def handle_info(
    {:tcp, _socket, data}, 
    state = {socket, transport})
  do
    processing_data(data, transport, socket)
    :ok = transport.setopts(socket, active: :once)
    {:noreply, state}
  end

  def handle_info({:tcp_closed, _port}, state) do
    {:stop, :tcp_closed, state}
  end

  def handle_cast(
    {:send_data, data}, state = {socket, transport})
  do
    :ok = transport.send(socket, data)
    {:noreply, state}
  end

  def send_data(pid, data) do
    GenServer.cast(pid, {:send_data, data})
  end

end
