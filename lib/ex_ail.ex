defmodule ExAil do
  @moduledoc """
  Documentation for `ExAil`.
  """

  alias ExAil.Client

  def base_url() do
    Application.fetch_env!(:ail, :api_base_url)
  end

  def token() do
    Application.fetch_env!(:ail, :api_token)
  end

  def version() do
    Application.fetch_env!(:ail, :api_version)
  end

  def ping() do
    Client.get!("ping")
  end
end
