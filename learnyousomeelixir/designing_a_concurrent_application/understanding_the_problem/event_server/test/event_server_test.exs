defmodule EventServerTest do
  use ExUnit.Case
  doctest EventServer

  test "greets the world" do
    assert EventServer.hello() == :world
  end
end
