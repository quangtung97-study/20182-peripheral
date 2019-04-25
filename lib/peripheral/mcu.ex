defmodule Peripheral.MCU do
  defstruct pid: nil, ref: nil, file: ""

  @msg_turn_on 0
  @msg_turn_off 1
  @msg_ping 2
  @msg_request_page 3
  @msg_recv_page 4
  @msg_start_boot 5

  alias Peripheral.MCUWorker

  def new(), do: %__MODULE__{}

  def monitor(mcu, pid) do
    ref = Process.monitor(pid)
    %{mcu | pid: pid, ref: ref}
  end

  def send_data(%__MODULE__{pid: nil}, _data) do
    :not_connected
  end

  def send_data(mcu, data) do
    Peripheral.Protocol.send_data(mcu.pid, data)
    :ok
  end

  def down(mcu) do
    %{mcu | pid: nil, ref: nil}
  end

  def handle_msg(mcu, data) do
    <<type, content :: binary>> = data
    case type do
      @msg_ping -> mcu

      @msg_start_boot ->
        file = File.read!("app.bin")
        IO.puts "Start Booting"
        %{mcu | file: file}

      @msg_request_page ->
        <<page_size>> = content
        file_size = byte_size(mcu.file)
        page = binary_part(mcu.file, 0, page_size)
        file = binary_part(mcu.file, page_size, file_size - page_size)
        send_data(mcu, <<1 + page_size, @msg_recv_page>> <> page)
        %{mcu | file: file}
    end
  end

  # External calls

  def turn_on() do
    MCUWorker.send_data(<<1, @msg_turn_on>>)
  end

  def turn_off() do
    MCUWorker.send_data(<<1, @msg_turn_off>>)
  end

end
