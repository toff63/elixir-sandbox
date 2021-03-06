defmodule EventServerV2Test do
  use ExUnit.Case

  test "Normalize" do
    assert Reminder.EventServerV2.normalize(98 * 24 * 60 * 60) == [
             0,
             49 * 24 * 60 * 60,
             49 * 24 * 60 * 60
           ]

    assert Reminder.EventServerV2.normalize(98 * 24 * 60 * 60 + 1) == [
             1,
             49 * 24 * 60 * 60,
             49 * 24 * 60 * 60
           ]

    assert Reminder.EventServerV2.normalize(5) == [5]
  end
end
