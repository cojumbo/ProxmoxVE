#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/cojumbo/ProxmoxVE/main/misc/build.func)

# Copyright (c) 2021-2026 community-scripts ORG
# Author: (your name here)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/konoe-akitoshi/shumoku

APP="Shumoku"
var_tags="${var_tags:-network;monitoring;diagram}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-6}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/shumoku ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Updating $APP"
  cd /opt/shumoku || exit
  git pull
  cd apps/server || exit
  make setup
  systemctl restart shumoku
  msg_ok "Updated $APP"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:8080${CL}"
echo -e "${INFO}${YW}Initial admin password was generated on first boot. Retrieve it with:${CL}"
echo -e "${GATEWAY}${BGN}pct exec ${CTID} -- cat /var/lib/shumoku/.bootstrap_admin_password${CL}"
