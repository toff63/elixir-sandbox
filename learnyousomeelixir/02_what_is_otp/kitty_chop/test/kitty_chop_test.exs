defmodule KittyChopTest do
  use ExUnit.Case
  doctest KittyChop

  test "greets the world" do
    assert KittyChop.hello() == :world
  end
end
