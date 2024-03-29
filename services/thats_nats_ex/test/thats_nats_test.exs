defmodule ThatsNatsTest do
  use ExUnit.Case
  doctest ThatsNats

  test "greets the world" do
    assert ThatsNats.hello() == :world
  end
end
