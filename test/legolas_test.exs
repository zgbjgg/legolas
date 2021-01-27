defmodule LegolasTest do
  use ExUnit.Case, async: false
  doctest Legolas

  require Legolas
  require Middle.Earth.Orc

  setup_all do
    target = spawn fn -> loop() end
    {:ok, target: target}
  end

  describe "legolas in action >>>-->" do
    test "add target", state do
      assert Legolas.add_target(state[:target]) == :ok
    end

    test "add collector", _state do
      assert Legolas.add_collector(self()) == :ok
    end

    test "add struct", _state do
      assert Legolas.add_struct(Middle.Earth.Orc) == :ok
    end

    test "trace messages", state do
      :ok = Legolas.add_target(state[:target])
      :ok = Legolas.add_collector(self())
      :ok = Legolas.add_struct(Middle.Earth.Orc)

      # send a message to target to be intercepted by Legolas >>>-->
      send state[:target], %Middle.Earth.Orc{name: "Azog"}

      # now check if our collector receives the message
      receive do
        {:message, %Middle.Earth.Orc{name: name}} ->
          assert name == "Azog"
      end
    end
  end

  defp loop do
    receive do
      _message -> loop()
    end
  end
end
