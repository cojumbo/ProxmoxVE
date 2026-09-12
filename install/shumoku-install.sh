#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: (your name here)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/konoe-akitoshi/shumoku

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  git \
  curl \
  unzip \
  ca-certificates \
  openssl \
  make
msg_ok "Installed Dependencies"

msg_info "Installing Bun"
curl -fsSL https://bun.sh/install | bash >/dev/null 2>&1
ln -sf /root/.bun/bin/bun /usr/local/bin/bun
ln -sf /root/.bun/bin/bunx /usr/local/bin/bunx
BUN_VERSION=$(bun --version)
msg_ok "Installed Bun $BUN_VERSION"

msg_info "Cloning Shumoku (Patience)"
git clone -q https://github.com/konoe-akitoshi/shumoku.git /opt/shumoku
cd /opt/shumoku || exit
RELEASE=$(git rev-parse --short HEAD)
msg_ok "Cloned Shumoku ($RELEASE)"

msg_info "Building Shumoku (Patience, this can take a while)"
cd /opt/shumoku/apps/server || exit
$STD make setup
msg_ok "Built Shumoku"

msg_info "Creating Data Directory"
mkdir -p /var/lib/shumoku
msg_ok "Created Data Directory"

msg_info "Generating Initial Admin Password"
# The server refuses to start on a non-loopback bind address unless an
# admin bootstrap secret is provided on first run. Generate one and keep
# it root-readable only.
ADMIN_PASSWORD=$(openssl rand -base64 18 | tr -dc 'A-Za-z0-9' | cut -c1-20)
echo -n "$ADMIN_PASSWORD" >/var/lib/shumoku/.bootstrap_admin_password
chmod 600 /var/lib/shumoku/.bootstrap_admin_password
msg_ok "Generated Initial Admin Password"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/shumoku.service
[Unit]
Description=Shumoku Network Topology Server
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/shumoku/apps/server
Environment=DATA_DIR=/var/lib/shumoku
Environment=PORT=8080
Environment=HOST=0.0.0.0
Environment=SHUMOKU_BOOTSTRAP_ADMIN_PASSWORD_FILE=/var/lib/shumoku/.bootstrap_admin_password
ExecStart=/usr/local/bin/bun run start
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now shumoku
msg_ok "Created Service"

echo "${RELEASE}" >/opt/shumoku_version.txt

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
