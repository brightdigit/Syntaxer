# Syntaxer Deployment Guide

This guide explains how to safely deploy Syntaxer with optimized performance.

## Performance Optimizations

Syntaxer now includes several performance optimizations that reduce code generation time by up to 90%:

1. **Pre-built Template Package**: Compiles SyntaxKit dependencies once and reuses them
2. **Dependency Caching**: Caches SyntaxKit locally to avoid repeated downloads
3. **Result Caching**: Caches generated code for frequently used DSL patterns
4. **Optimized Compilation**: Uses release mode and whole-module optimization

## Deployment Options

### Option 1: Docker Deployment (Recommended)

Create a `Dockerfile`:

```dockerfile
# Build stage
FROM swift:6.0-jammy as builder

WORKDIR /app
COPY . .

# Build with optimizations
RUN swift build -c release

# Prepare template and cache
RUN .build/release/syntaxer prepare --verbose

# Runtime stage
FROM swift:6.0-jammy-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy binaries and cache
COPY --from=builder /app/.build/release/syntaxer /usr/local/bin/
COPY --from=builder /app/.build/release/syntaxer-api /usr/local/bin/
COPY --from=builder /app/Packages /app/Packages
COPY --from=builder /root/.cache/syntaxer* /root/.cache/

# Expose API port
EXPOSE 8080

# Default to running the API
CMD ["syntaxer-api"]
```

Build and run:

```bash
docker build -t syntaxer:latest .
docker run -p 8080:8080 syntaxer:latest
```

### Option 2: systemd Service (Linux)

1. Build the binaries:
```bash
swift build -c release
```

2. Prepare the cache:
```bash
.build/release/syntaxer prepare
```

3. Create systemd service file `/etc/systemd/system/syntaxer-api.service`:

```ini
[Unit]
Description=Syntaxer API Service
After=network.target

[Service]
Type=simple
User=syntaxer
Group=syntaxer
WorkingDirectory=/opt/syntaxer
ExecStart=/opt/syntaxer/syntaxer-api
Restart=on-failure
RestartSec=10

# Security hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/cache/syntaxer

# Resource limits
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
```

4. Install and start:
```bash
sudo cp .build/release/syntaxer-api /opt/syntaxer/
sudo systemctl enable syntaxer-api
sudo systemctl start syntaxer-api
```

### Option 3: macOS Launch Agent

1. Build and prepare:
```bash
swift build -c release
./build/release/syntaxer prepare
```

2. Create `~/Library/LaunchAgents/com.syntaxer.api.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" 
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.syntaxer.api</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/syntaxer-api</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/var/log/syntaxer.log</string>
    <key>StandardErrorPath</key>
    <string>/var/log/syntaxer.error.log</string>
</dict>
</plist>
```

3. Load the service:
```bash
launchctl load ~/Library/LaunchAgents/com.syntaxer.api.plist
```

## Environment Configuration

Create `.env` file for configuration:

```bash
# Server configuration
SYNTAXER_HOST=0.0.0.0
SYNTAXER_PORT=8080

# Performance settings
SYNTAXER_USE_CACHE=true
SYNTAXER_USE_TEMPLATE=true
SYNTAXER_CACHE_MAX_SIZE=1000
SYNTAXER_CACHE_MAX_AGE=86400

# Security settings
SYNTAXER_MAX_REQUEST_SIZE=100000
SYNTAXER_DEFAULT_TIMEOUT=30
SYNTAXER_MAX_TIMEOUT=240

# Logging
SYNTAXER_LOG_LEVEL=info
```

## Security Considerations

1. **Code Execution**: Syntaxer executes Swift code. Deploy behind a firewall and implement rate limiting.

2. **Resource Limits**: Set appropriate memory and CPU limits to prevent resource exhaustion.

3. **Network Security**: 
   - Use TLS/SSL for production deployments
   - Implement API key authentication if exposed publicly
   - Set up CORS policies appropriately

4. **File System**: The service creates temporary files. Ensure:
   - Adequate disk space
   - Regular cleanup of temp directories
   - Restrictive file permissions (700)

## Monitoring

Monitor these key metrics:

- **Response Time**: Track p50, p95, p99 latencies
- **Cache Hit Rate**: Should be >80% for common patterns
- **Resource Usage**: CPU, memory, disk I/O
- **Error Rate**: Track compilation failures

Example monitoring with Prometheus:

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'syntaxer'
    static_configs:
      - targets: ['localhost:8080']
    metrics_path: '/metrics'
```

## Scaling

For high traffic:

1. **Horizontal Scaling**: Run multiple instances behind a load balancer
2. **Shared Cache**: Use Redis for distributed caching
3. **Queue System**: Implement async processing for large requests
4. **CDN**: Cache frequently requested outputs

## Troubleshooting

### Slow Performance

1. Check if template is prepared:
```bash
syntaxer prepare --verbose
```

2. Verify cache is working:
```bash
ls -la ~/.cache/syntaxer*
```

3. Monitor compilation times in logs

### Build Failures

1. Ensure Swift 6.0+ is installed
2. Check network connectivity for package downloads
3. Verify sufficient disk space
4. Run with verbose logging

### Memory Issues

1. Limit concurrent requests
2. Implement request queuing
3. Set up memory monitoring alerts

## Best Practices

1. **Warm Up**: Run `syntaxer prepare` before deploying
2. **Regular Updates**: Keep SyntaxKit and dependencies updated
3. **Backup Cache**: Include cache in deployment artifacts
4. **Health Checks**: Implement proper health endpoints
5. **Graceful Shutdown**: Handle SIGTERM for clean shutdowns