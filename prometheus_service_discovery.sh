#!/usr/bin/bash

# Configure Prometheus Service Discovery
sudo tee /etc/prometheus/prometheus.yml << EOF 
global:
  scrape_interval: 1s
  evaluation_interval: 1s

scrape_configs:
  - job_name: 'node'
    ec2_sd_configs:
      - region: us-east-1
        access_key: AKIAYN3PIIUBJMNPNXMV
        secret_key: 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
        port: 9100
EOF

# After executing this file
# Run this to restart the service
# sudo systemctl restart prometheus