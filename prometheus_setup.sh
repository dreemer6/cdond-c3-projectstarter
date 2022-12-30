#!/usr/bin/bash
# Create new user and directories for the
# Prometheus configuration and to host its data
sudo useradd --no-create-home prometheus
sudo mkdir /etc/prometheus
sudo mkdir /var/lib/prometheus

# Install Prometheus
wget https://github.com/prometheus/prometheus/releases/download/v2.41.0/prometheus-2.41.0.linux-amd64.tar.gz
tar xvfz prometheus-2.41.0.linux-amd64.tar.gz

sudo cp prometheus-2.41.0.linux-amd64/prometheus /usr/local/bin
sudo cp prometheus-2.41.0.linux-amd64/promtool /usr/local/bin/
sudo cp -r prometheus-2.41.0.linux-amd64/consoles /etc/prometheus
sudo cp -r prometheus-2.41.0.linux-amd64/console_libraries /etc/prometheus

sudo cp prometheus-2.41.0.linux-amd64/promtool /usr/local/bin/
rm -rf prometheus-2.41.0.linux-amd64.tar.gz prometheus-2.41.0.linux-amd64

# Configure Prometheus to monitor itself
sudo tee /etc/prometheus/prometheus.yml << EOF
global:
  scrape_interval: 15s
  external_labels:
    monitor: 'prometheus'

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
EOF

# Make Prometheus to be available as a service.
# Every time we reboot the system Prometheus will start with the OS
sudo tee /etc/systemd/system/prometheus.service << EOF
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOF


# Change the permissions of the directories, files and binaries we just added to our system.
sudo chown prometheus:prometheus /etc/prometheus
sudo chown prometheus:prometheus /usr/local/bin/prometheus
sudo chown prometheus:prometheus /usr/local/bin/promtool
sudo chown -R prometheus:prometheus /etc/prometheus/consoles
sudo chown -R prometheus:prometheus /etc/prometheus/console_libraries
sudo chown -R prometheus:prometheus /var/lib/prometheus

# Configure systemd
sudo systemctl daemon-reload
sudo systemctl enable prometheus