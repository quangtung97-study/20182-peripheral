defmodule Peripheral.MCUWorker do
  use GenServer

  alias Peripheral.MCU

  # Called from supervisor
  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  # Called from protocol
  def register(pid) do
    GenServer.call(__MODULE__, {:register, pid})
  end

  # External Calls
  def send_data(data) do
    GenServer.call(__MODULE__, {:send_data, data})
  end

  # Called from protocol
  def msg(data) do
    GenServer.call(__MODULE__, {:msg, data})
  end

  # GenServer callbacks

  def init([]) do
    {:ok, MCU.new()}
  end

  def handle_call({:register, pid}, _from, mcu) do
    {:reply, :ok, MCU.monitor(mcu, pid)}
  end

  def handle_call({:send_data, data}, _from, mcu) do
    {:reply, MCU.send_data(mcu, data), mcu}
  end

  def handle_call({:msg, data}, _from, mcu) do
    {:reply, :ok, MCU.handle_msg(mcu, data)}
  end

  def handle_info({:DOWN, ref, :process, _object, _reason}, mcu = %MCU{ref: ref}) do
    {:noreply, MCU.down(mcu)}
  end

  def handle_info(_data, mcu) do
    {:noreply, mcu}
  end
end
