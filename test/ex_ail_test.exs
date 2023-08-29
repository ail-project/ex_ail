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

  test "submit flat item", %{bypass: bypass} do
    test_data = "coucou"

    expected_payload = %{
      "data" => ExAil.encode_and_compress(test_data),
      "data-sha256" => :crypto.hash(:sha256, test_data) |> Base.encode16(case: :lower),
      "meta" => "",
      "source" => "nonempty",
      "source_uuid" => "6288c01f-c595-4d22-bef1-9d05ab775865",
      "default_encoding" => "utf-8"
    }

    Bypass.expect(bypass, fn conn ->
      {:ok, payload, _conn} = Plug.Conn.read_body(conn)
      assert payload == Jason.encode!(expected_payload)
      Plug.Conn.resp(conn, 200, ~s|{"status": "success"}|)
    end)

    assert {:ok, %{"status" => "success"}} =
             ExAil.feed_json_item(
               test_data,
               "",
               "nonempty",
               "6288c01f-c595-4d22-bef1-9d05ab775865",
               "utf-8"
             )
  end

  test "submit map item", %{bypass: bypass} do
    test_data = "coucou"

    expected_payload = %{
      "data" => ExAil.encode_and_compress(test_data),
      "data-sha256" => :crypto.hash(:sha256, test_data) |> Base.encode16(case: :lower),
      "meta" => "",
      "source" => "nonempty",
      "source_uuid" => "6288c01f-c595-4d22-bef1-9d05ab775865",
      "default_encoding" => "utf-8"
    }

    dict_payload = %{
      "data" => test_data,
      "meta" => "",
      "source" => "nonempty",
      "source_uuid" => "6288c01f-c595-4d22-bef1-9d05ab775865",
      "default_encoding" => "utf-8"
    }

    Bypass.expect(bypass, fn conn ->
      {:ok, payload, _conn} = Plug.Conn.read_body(conn)
      assert payload == Jason.encode!(expected_payload)
      Plug.Conn.resp(conn, 200, ~s|{"status": "success"}|)
    end)

    assert {:ok, %{"status" => "success"}} = ExAil.feed_json_item(dict_payload)
  end
end
