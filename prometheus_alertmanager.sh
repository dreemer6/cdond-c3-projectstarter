wget https://github.com/prometheus/alertmanager/releases/download/v0.25.0/alertmanager-0.25.0.linux-amd64.tar.gz
tar xvfz alertmanager-0.25.0.linux-amd64.tar.gz

sudo cp alertmanager-0.25.0.linux-amd64/alertmanager /usr/local/bin
sudo cp alertmanager-0.25.0.linux-amd64/amtool /usr/local/bin/
sudo mkdir /var/lib/alertmanager

rm -rf alertmanager*

sudo tee /etc/prometheus/alertmanager.yml << EOF
route:
  group_by: [Alertname]
  receiver: email-me

receivers:
- name: email-me
  email_configs:
  - to: EMAIL_YO_WANT_TO_SEND_EMAILS_TO
    from: YOUR_EMAIL_ADDRESS
    smarthost: smtp.gmail.com:587
    auth_username: YOUR_EMAIL_ADDRESS
    auth_identity: YOUR_EMAIL_ADDRESS
    auth_password: YOUR_EMAIL_PASSWORD
EOF

sudo tee /etc/systemd/system/alertmanager.service << EOF
[Unit]
Description=Alert Manager
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=prometheus
Group=prometheus
ExecStart=/usr/local/bin/alertmanager \
  --config.file=/etc/prometheus/alertmanager.yml \
  --storage.path=/var/lib/alertmanager

Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable alertmanager
sudo systemctl start alertmanager

# Create a rule
sudo tee /etc/prometheus/rules.yml << EOF
groups:
- name: Down
  rules:
  - alert: InstanceDown
    expr: up == 0
    for: 3m
    labels:
      severity: 'critical'
    annotations:
      summary: "Instance  is down"
      description: " of job  has been down for more than 3 minutes."
EOF

# Change permissions of file and directories just added
sudo chown -R prometheus:prometheus /etc/prometheus

sudo tee >> /etc/prometheus/prometheus.yml << EOF

rule_files:
 - /etc/prometheus/rules.yml

alerting:
  alertmanagers:
  - static_configs:
    - targets:
      - localhost:9093
EOF

# Reload systemd
sudo systemctl restart prometheus