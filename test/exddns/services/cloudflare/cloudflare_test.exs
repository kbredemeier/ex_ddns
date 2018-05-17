defmodule ExDDNS.Services.CloudflareTest do
  use ExUnit.Case, async: true

  import Tesla.Mock

  alias Tesla.Env
  alias ExDDNS.Services.Cloudflare
  alias ExDDNS.Services.Cloudflare.Config

  describe "list_dns_records/1" do
    test "lists the dns records from the api" do
      url = "https://api.cloudflare.com/client/v4/zones/zone-123/dns_records"

      mock(fn %{method: :get, url: ^url} ->
        %Env{
          status: 200,
          body: %{
            "errors" => [],
            "messages" => [],
            "result" => [
              %{
                "content" => "127.0.0.1",
                "created_on" => "2018-05-17T18:24:08.734104Z",
                "id" => "record-123",
                "locked" => false,
                "meta" => %{"auto_added" => false, "managed_by_apps" => false},
                "modified_on" => "2018-05-17T18:24:08.734104Z",
                "name" => "example.com",
                "proxiable" => true,
                "proxied" => false,
                "ttl" => 1,
                "type" => "A",
                "zone_id" => "zone-123",
                "zone_name" => "example.com"
              }
            ],
            "result_info" => %{
              "count" => 1,
              "page" => 1,
              "per_page" => 20,
              "total_count" => 1,
              "total_pages" => 1
            },
            "success" => true
          }
        }
      end)

      assert {:ok, records} =
               build_config()
               |> Cloudflare.client()
               |> Cloudflare.list_dns_records()

      assert records == [
               %{
                 "content" => "127.0.0.1",
                 "created_on" => "2018-05-17T18:24:08.734104Z",
                 "id" => "record-123",
                 "locked" => false,
                 "meta" => %{"auto_added" => false, "managed_by_apps" => false},
                 "modified_on" => "2018-05-17T18:24:08.734104Z",
                 "name" => "example.com",
                 "proxiable" => true,
                 "proxied" => false,
                 "ttl" => 1,
                 "type" => "A",
                 "zone_id" => "zone-123",
                 "zone_name" => "example.com"
               }
             ]
    end
  end

  describe "update_dns_record/3" do
    test "updates a dns record" do
      url =
        "https://api.cloudflare.com/client/v4/zones/zone-123/dns_records/record-123"

      mock(fn %{method: :put, url: ^url} ->
        %Env{
          status: 200,
          body: %{
            "errors" => [],
            "messages" => [],
            "result" => %{
              "content" => "127.0.0.1",
              "created_on" => "2018-05-17T18:24:08.734104Z",
              "id" => "record-123",
              "locked" => false,
              "meta" => %{"auto_added" => false, "managed_by_apps" => false},
              "modified_on" => "2018-05-17T18:24:08.734104Z",
              "name" => "example.com",
              "proxiable" => true,
              "proxied" => false,
              "ttl" => 1,
              "type" => "A",
              "zone_id" => "zone-123",
              "zone_name" => "example.com"
            },
            "success" => true
          }
        }
      end)

      assert :ok =
               build_config()
               |> Cloudflare.client()
               |> Cloudflare.update_dns_record("record-123", %{
                 type: "A",
                 content: "127.0.0.1",
                 name: "example.com"
               })
    end
  end

  def build_config(opts \\ []) do
    applied_opts =
      Keyword.merge(
        [
          x_auth_email: "user@example.com",
          x_auth_key: "xxx",
          zone_id: "zone-123",
          dns_record_id: "record-123",
          domain: "example.com"
        ],
        opts
      )

    struct!(Config, applied_opts)
  end
end
