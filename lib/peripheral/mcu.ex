defmodule Peripheral.MCU do
  use GenServer

  @msg_turn_on 0
  @msg_turn_off 1

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def register(pid) do
    GenServer.call(__MODULE__, {:register, pid})
  end

  def send(data) do
    GenServer.call(__MODULE__, {:send, data})
  end

  def turn_on() do
    send(<<1, @msg_turn_on>>)
  end

  def turn_off() do
    send(<<1, @msg_turn_off>>)
  end

  def init([]) do
    {:ok, {nil, nil}}
  end

  def handle_call({:register, pid}, _from, _state) do
    ref = Process.monitor(pid)
    {:reply, :ok, {pid, ref}}
  end

  def handle_call({:send, _data}, _from, state = {nil, _ref}) do
    {:reply, :not_connected, state}
  end

  def handle_call({:send, data}, _from, state = {pid, _ref}) do
    Peripheral.Protocol.send(pid, data)
    {:reply, :ok, state}
  end

  def handle_info({:DOWN, ref, :process, _object, _reason}, {_pid, ref}) do
    {:noreply, {nil, nil}}
  end

  def handle_info(_data, state) do
    {:noreply, state}
  end

end
