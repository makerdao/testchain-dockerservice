defmodule DockerTest do
  use ExUnit.Case
  doctest Docker

  test "greets the world" do
    assert Docker.hello() == :world
  end
end
