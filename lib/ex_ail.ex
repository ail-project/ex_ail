defmodule ExAil do
  @moduledoc """
  Documentation for `ExAil`.
  """

  require Logger

  alias ExAil.Client

  def base_location() do
    Application.fetch_env!(:ex_ail, :api_base_location)
  end

  def token() do
    Application.fetch_env!(:ex_ail, :api_token)
  end

  def version() do
    Application.fetch_env!(:ex_ail, :api_version)
  end

  def protocol() do
    Application.fetch_env!(:ex_ail, :api_protocol)
  end

  def port() do
    Application.fetch_env!(:ex_ail, :api_port)
  end

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
end
