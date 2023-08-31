defmodule ExAil do
  @moduledoc """
  Documentation for `ExAil`.
  """

  require Logger

  alias ExAil.Client

  @type data :: binary
  @type metadata :: String.t()
  @type source :: String.t()
  @type source_uuid :: String.t()
  @type default_encoding :: String.t()

  @type url :: String.t()
  @type har :: boolean()
  @type screenshot :: boolean()
  @type deph_limit :: non_neg_integer()
  # frequency can be 'monthly', 'weekly', 'daily', 'hourly'
  @type frequency :: String.t()
  @type cookiejar :: String.t()
  # proxy can be set to 'onion', 'tor' or 'force_tor'
  @type proxy :: String.t()
  # [%{"name" =>  "", "value" => ""}]
  @type cookies :: list()

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

  @spec feed_json_item(data, metadata, source, source_uuid, default_encoding) ::
          {:error, {:client_error, any} | {:http_error, any} | {:server_error, any}} | {:ok, any}
  def feed_json_item(data, metadata, source, source_uuid, default_encoding)
      when is_binary(data) and is_binary(metadata) and is_binary(source) and
             is_binary(source_uuid) and is_binary(default_encoding) do
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

  @spec crawl_url(url, har, screenshot, deph_limit, frequency, cookiejar, cookies, proxy) ::
          {:error, {:client_error, any} | {:http_error, any} | {:server_error, any}} | {:ok, any}
  def crawl_url(
        url,
        har \\ false,
        screenshot \\ false,
        depth_limit \\ 1,
        frequency \\ "",
        cookiejar \\ "",
        cookies \\ [],
        proxy \\ "force_tor"
      )
      when is_binary(url) and is_binary(cookiejar) and is_binary(proxy) and is_binary(frequency) and
             is_boolean(screenshot) and is_boolean(har) and
             (is_integer(depth_limit) and depth_limit >= 0) do
    dict = %{
      "url" => url,
      "har" => har,
      "screenshot" => screenshot,
      "depth_limit" => depth_limit
    }

    dict =
      case frequency do
        "" ->
          dict

        "monthly" ->
          Map.put(dict, "frequency", "monthly")

        "weekly" ->
          Map.put(dict, "frequency", "weekly")

        "daily" ->
          Map.put(dict, "frequency", "monthly")

        "hourly" ->
          Map.put(dict, "frequency", "hourly")

        _ ->
          dict
      end

    dict =
      case proxy do
        "" ->
          dict

        "onion" ->
          Map.put(dict, "proxy", "onion")

        "tor" ->
          Map.put(dict, "proxy", "tor")

        "force_tor" ->
          Map.put(dict, "proxy", "force_tor")

        _ ->
          dict
      end

    dict =
      case check_url(proxy) do
        {:ok} ->
          Map.put(dict, "proxy", proxy)

        _ ->
          dict
      end

    dict =
      case cookiejar do
        "" ->
          dict

        _ ->
          Map.put(dict, "cookiejar", cookiejar)
      end

    dict =
      case cookies do
        [] ->
          dict

        [_ | _] ->
          Map.put(dict, "cookies", cookies)
      end

    case Client.post("add/crawler/task", Jason.encode!(dict)) do
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

  @spec encode_and_compress(data) :: data
  def encode_and_compress(data) do
    data
    |> :zlib.gzip()
    |> Base.encode64()
  end

  defp check_url(value) do
    case URI.parse(value) do
      %URI{scheme: nil} -> {:error, "Missing a scheme"}
      %URI{host: nil} -> {:error, "Missing a host"}
      %URI{host: host} -> validate_host(host)
    end
  end

  defp validate_host(host) do
    case :inet.gethostbyname(Kernel.to_charlist(host)) do
      {:ok, _} -> {:ok}
      {:error, _} -> {:error, "invalid host"}
    end
  end
end
