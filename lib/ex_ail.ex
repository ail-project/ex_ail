defmodule ExAil do
  @moduledoc """
  Documentation for `ExAil`.
  """

  require Logger

  alias ExAil.Client

  @type data() :: binary
  @type metadata() :: String.t()
  @type source() :: String.t()
  @type source_uuid() :: String.t()
  @type default_encoding() :: String.t()

  @spec base_location :: String.t()
  def base_location() do
    Application.fetch_env!(:ex_ail, :api_base_location)
  end

  @spec token :: String.t()
  def token() do
    Application.fetch_env!(:ex_ail, :api_token)
  end

  @spec version :: Integer
  def version() do
    Application.fetch_env!(:ex_ail, :api_version)
  end

  @spec protocol :: String.t()
  def protocol() do
    Application.fetch_env!(:ex_ail, :api_protocol)
  end

  @spec port :: Integer
  def port() do
    Application.fetch_env!(:ex_ail, :api_port)
  end

  @spec ping :: {:error} | {:ok}
  def ping() do
    case Client.get("ping") do
      {:ok, resp} ->
        case resp do
          %{body: %{"status" => "pong"}, status_code: 200} ->
            {:ok}

          what ->
            Logger.error(what)
            {:error}
        end

      _ ->
        {:error}
    end
  end

  @spec feed_json_item(data(), metadata(), source(), source_uuid(), default_encoding()) ::
          {:error, {:client_error, any} | {:http_error, any} | {:server_error, any}} | {:ok, any}
  def feed_json_item(data, metadata, source, source_uuid, default_encoding) do
    case source do
      "" ->
        {:error, "source can not be blank."}

      _ ->
        dict = %{
          "data" => encode_and_compress(data),
          "data-sha256" => :crypto.hash(:sha256, data) |> Base.encode16(case: :lower),
          "meta" => metadata,
          "source" => source,
          "source_uuid" => source_uuid,
          "default_encoding" => default_encoding
        }

        case Client.post("import/json/item", Jason.encode!(dict)) do
          {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
            {:ok, response_body}

          {:ok, %HTTPoison.Response{status_code: status_code, body: response_body}}
          when status_code in 400..499 ->
            {:error, {:client_error, response_body}}

          {:ok, %HTTPoison.Response{status_code: status_code, body: response_body}}
          when status_code in 500..599 ->
            {:error, {:server_error, response_body}}

          {:error, %HTTPoison.Error{reason: reason}} ->
            {:error, {:http_error, reason}}
        end
    end
  end

  @spec feed_json_item(map) ::
          {:error, {:client_error, any} | {:http_error, any} | {:server_error, any}} | {:ok, any}
  def feed_json_item(%{
        "data" => data,
        "meta" => metadata,
        "source" => source,
        "source_uuid" => source_uuid,
        "default_encoding" => default_encoding
      }) do
    feed_json_item(data, metadata, source, source_uuid, default_encoding)
  end

  @spec encode_and_compress(data) :: data
  def encode_and_compress(data) do
    data
    |> :zlib.gzip()
    |> Base.encode64()
  end
end
