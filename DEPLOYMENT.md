# Deployment Guide (Porkbun + HTTPS + Load Ready)

This app is ready to run on a single host with a reverse proxy, TLS, and systemd supervision. Use this as a checklist.

## 1) DNS (Porkbun)
- Create an `A` (and `AAAA` if IPv6) record pointing your domain to the server IP.
- If using DNS challenge for certs, generate a Porkbun API key/secret (Account -> API) and set them for your proxy.

## 2) Reverse Proxy with TLS
Example **Caddyfile** (auto HTTPS, gzip, basic rate limits):
```caddyfile
harmony.mom {
  encode gzip zstd
  route {
    @api path /health /time /time/* /autopilot/* /docket /history /senators* /senators/*
    rate_limit * 10r/s
    reverse_proxy 127.0.0.1:8080
  }
}
```

If you prefer NGINX:
```nginx
server {
  listen 80;
  server_name harmony.mom;
  return 301 https://$host$request_uri;
}

server {
  listen 443 ssl http2;
  server_name harmony.mom;

  # ssl_certificate /path/fullchain.pem;
  # ssl_certificate_key /path/privkey.pem;

  client_max_body_size 5m;
  gzip on;

  location / {
    proxy_pass http://127.0.0.1:8080;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto https;
  }

  location /health { proxy_pass http://127.0.0.1:8080/health; }
}
```

## 3) Systemd Service
Create `/etc/systemd/system/harmony.service`:
```ini
[Unit]
Description=Harmony Chamber
After=network.target

[Service]
Type=simple
WorkingDirectory=/srv/harmony_chamber
ExecStart=/usr/bin/gleam run -m harmony_chamber
EnvironmentFile=/etc/harmony.env
Restart=on-failure
RestartSec=2
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
```

Then:
```
sudo systemctl daemon-reload
sudo systemctl enable harmony
sudo systemctl start harmony
```

## 4) Environment
Place secrets in `/etc/harmony.env` (readable only by service user):
```
OPENAI_API_KEY=...
HARMONY_AUTOPILOT_MODE=both   # or time/debate
HARMONY_AUTOPILOT_TICK_MS=500 # tune for load
HARMONY_AUTOPILOT_STEPS=3
HARMONY_MEMORY_CONTEXT_TIMEOUT_MS=4000
HARMONY_DEBATE_LLM_TIMEOUT_MS=20000
HARMONY_CORE_DEBATE_MODEL=gpt-4.1-turbo   # optional override
```

## 5) Persistence & Backups
- `session_snapshot.etf` (and time session state) should live under `WorkingDirectory` and be included in backups.
- If you mount a separate volume, point `HARMONY_SNAPSHOT_PATH` there.

## 6) Health & Monitoring
- `/health` returns 200 for liveness.
- Tail logs via `journalctl -u harmony -f`.
- Consider uptime monitoring that hits `/health` over HTTPS.

## 7) Load Safety
- Keep `steps_per_tick` modest (2–3) if traffic spikes; raise only when you have headroom.
- The reverse proxy rate limits above are conservative; adjust per your needs.

## 8) Zero-Downtime Deploys (optional)
- Use a process manager or systemd `ExecReload` with a wrapper script to restart gracefully.
- For larger scale, front with a load balancer and run multiple instances.

Update domains/paths as needed for your env. This keeps the site HTTPS-only, supervised, and snapshot-safe.

## DigitalOcean specifics
- Create a Droplet (Debian/Ubuntu) and open ports 80/443 in the cloud firewall.
- Add A/AAAA records in Porkbun pointing to the Droplet IP.
- Install Caddy or NGINX; for Caddy with DNS challenge use Porkbun plugin or HTTP-01 with port 80 open.
- Keep the Gleam service bound to localhost (mist is on 8080) and let the proxy handle TLS.
- Snapshot your Droplet and/or back up `/srv/harmony_chamber` and `/etc/harmony.env`.

- On DigitalOcean, in your Project -> Networking -> Firewalls, add a rule allowing inbound TCP 80 and 443 to your Droplet. If using the default Droplet-level firewall, ensure both ports are open there too.
- Outbound HTTPS (443) must be open so Caddy/NGINX can fetch certs from Let’s Encrypt/OpenAI.
