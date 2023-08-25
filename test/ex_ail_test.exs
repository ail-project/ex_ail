defmodule ExAilTest do
  use ExUnit.Case, async: true

  require Logger

  setup do
    bypass = Bypass.open(port: ExAil.port())
    {:ok, bypass: bypass}
  end

  test "ping", %{bypass: bypass} do
    Bypass.expect(bypass, "GET", "/api/v1/ping", fn conn ->
      Plug.Conn.resp(conn, 200, ~s<{"status": "pong"}>)
    end)
    assert {:ok} = ExAil.ping()

    Bypass.down(bypass)
    assert {:error} = ExAil.ping()

    Bypass.up(bypass)
    assert {:ok} = ExAil.ping()
  end
end
