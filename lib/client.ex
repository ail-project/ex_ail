defmodule ExAil.Client do
  use HTTPoison.Base

  require Logger

  @endpoint ExAil.base_location()
  @token ExAil.token()
  @version ExAil.version()
  @protocol ExAil.protocol()
  @port Integer.to_string(ExAil.port())

  @impl true
  def process_request_url(url) do
    @protocol <> "://" <> @endpoint <> ":" <> @port <> "/api/" <> @version <> "/" <> url
  end

  @impl true
  def process_request_headers(headers) do
    [
      {"Authorization", @token},
      {"Accept", "application/json"},
      {"content-type", "application/json"},
      {"User-Agent", "ex_ail version TODO"}
      | headers
    ]
  end

  @impl true
  def process_request_options(options) do
    case @protocol do
      "https" ->
        [{:ssl, [{:verify, :verify_none}]} | options]

      "http" ->
        options

      _ ->
        options
    end
  end

  @impl true
  def process_response_body(body) do
    # attempting the gracefully decode json body
    case Jason.decode(body) do
      {:ok, data} ->
        data

      {:error, _reason} ->
        body
    end
  end
end
