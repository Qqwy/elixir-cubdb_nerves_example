defmodule CubdbNervesExampleTest do
  use ExUnit.Case
  doctest CubdbNervesExample

  test "greets the world" do
    assert CubdbNervesExample.hello() == :world
  end
end
