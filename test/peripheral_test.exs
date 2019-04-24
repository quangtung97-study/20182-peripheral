defmodule PeripheralTest do
  use ExUnit.Case
  doctest Peripheral

  test "greets the world" do
    assert Peripheral.hello() == :world
  end
end
