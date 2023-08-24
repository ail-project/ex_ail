defmodule ExAil.Client do
  use HTTPoison.Base

  @endpoint ExAil.base_url()
  @token ExAil.token()
  @version ExAil.version()

  @impl true
  def process_request_url(url) do
    @endpoint <> "/api/" <> @version <> "/" <> url
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
    [{:ssl, [{:verify, :verify_none}]} | options]
  end

  @impl true
  def process_response_body(body) do
    Jason.decode!(body)
  end
end
