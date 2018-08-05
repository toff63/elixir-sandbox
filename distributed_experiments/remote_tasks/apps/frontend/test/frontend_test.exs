defmodule FrontendTest do
  use ExUnit.Case
  doctest Frontend

  test "greets the world" do
    assert Frontend.hello() == :world
  end
end
