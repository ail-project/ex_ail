defmodule ExAilTest do
  use ExUnit.Case
  doctest ExAil

  test "greets the world" do
    assert ExAil.hello() == :world
  end
end
