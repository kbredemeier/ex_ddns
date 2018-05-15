defmodule ExDDNS.State.CurrentIp do
  use Tesla

  alias Tesla.Env

  plug(Tesla.Middleware.BaseUrl, "https://canihazip.com")

  def fetch do
    case get("/s") do
      {:ok, %Env{status: 200, body: ip}} -> {:ok, ip}
      {:ok, %Env{status: status}} -> {:error, status}
      error -> error
    end
  end
end
