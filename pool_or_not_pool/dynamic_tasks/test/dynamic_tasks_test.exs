defmodule DynamicTasksTest do
  use ExUnit.Case
  doctest DynamicTasks

  test "greets the world" do
    assert DynamicTasks.hello() == :world
  end
end
