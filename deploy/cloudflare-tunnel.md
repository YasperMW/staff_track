# Cloudflare Tunnel Setup (Free Alternative to ngrok)

## Installation
```bash
# Install cloudflared
npm install -g cloudflared

# Or download binary from https://github.com/cloudflare/cloudflared/releases
```

## Usage
```bash
# Expose local API (port 8000)
cloudflared tunnel --url http://localhost:8000

# Or with custom subdomain (requires account)
cloudflared tunnel --url http://localhost:8000 --hostname your-api.yourdomain.com
```

## Advantages over ngrok:
- Free and more stable
- No rate limiting
- HTTPS automatically
- Custom domains supported
- Better performance

## Update AppConfig
```dart
class AppConfig {
  static const String apiBaseUrl = "https://your-tunnel-url.trycloudflare.com";
}
```
