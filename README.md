# ExDDNS

An elixir application to keep track of the public ip address of the machine that
runs the application and update a dns record in case the public ip changes.

## Usage

```
$ git clone https://github.com/kbredemeier/ex_ddns.git
$ cd ex_ddns
$ docker build --tag exddns:latest .
$ docker run \
  -e EX_DDNS_SERVICE='Cloudflare' \
  -e CLOUDFLARE_X_AUTH_EMAIL='user@example.com' \
  -e CLOUDFLARE_X_AUTH_KEY='xxxx' \
  -e CLOUDFLARE_ZONE_ID='xxxx' \
  -e CLOUDFLARE_DOMAIN='example.com' \
  -e CLOUDFLARE_DNS_RECORD_ID='xxxx' \
  --name ex_ddns
  ex_ddns
```
