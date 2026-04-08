#!/bin/bash

# --- Color Palette ---
ACCENT='\033[1;36m'  # Cyan
SUCCESS='\033[1;32m' # Green
DANGER='\033[1;31m'  # Red
INFO='\033[1;34m'    # Blue
WARN='\033[1;33m'    # Yellow
MAGENTA='\033[1;35m' # Magenta
BOLD='\033[1m'
NC='\033[0m'         # No Color

get_status() {
  if [ "$(docker ps -aq -f name=cockpit)" ]; then
    if [ "$(docker ps -q -f name=cockpit)" ]; then
      STATUS="${SUCCESS}● ON (Running)${NC}"
      IS_RUNNING=true
      IS_INSTALLED=true
    else
      STATUS="${DANGER}○ OFF (Stopped)${NC}"
      IS_RUNNING=false
      IS_INSTALLED=true
    fi
  else
    STATUS="${BOLD}◌ NOT INSTALLED${NC}"
    IS_RUNNING=false
    IS_INSTALLED=false
  fi
}

get_ips() {
  PUBLIC_IP=$(curl -s ifconfig.me || echo "Error")
  TAILSCALE_IP=$(tailscale ip -4 2>/dev/null | head -n 1)
  LOCAL_IP=$(hostname -I | awk '{print $1}')

  [ -z "$PUBLIC_IP" ] && PUBLIC_IP="${DANGER}Not Found${NC}"
  [ -z "$TAILSCALE_IP" ] && TAILSCALE_IP="${WARN}Not Connected${NC}"
  [ -z "$LOCAL_IP" ] && LOCAL_IP="${DANGER}Not Found${NC}"
}

# --- Action Functions ---

toggle_on() {
  if [ "$IS_INSTALLED" = false ]; then
    echo -e "\n${DANGER}❌ Not installed! Use Option 1 first.${NC}"; sleep 2
  elif [ "$IS_RUNNING" = true ]; then
    echo -e "\n${WARN}⚠️  Already ON!${NC}"; sleep 1
  else
    echo -e "\n${SUCCESS}▶️  Starting Cockpit...${NC}"
    docker start cockpit >/dev/null
    sleep 2
  fi
}

toggle_off() {
  if [ "$IS_RUNNING" = false ]; then
    echo -e "\n${WARN}⚠️  Already OFF!${NC}"; sleep 1
  else
    echo -e "\n${DANGER}⏹️  Stopping Cockpit...${NC}"
    docker stop cockpit >/dev/null
    sleep 2
  fi
}

restart_cockpit() {
  if [ "$IS_INSTALLED" = false ]; then
    echo -e "\n${DANGER}❌ Nothing to restart!${NC}"; sleep 2
  else
    echo -e "\n${INFO}🔄 Restarting Cockpit...${NC}"
    docker restart cockpit >/dev/null
    echo -e "${SUCCESS}✅ Restarted!${NC}"
    sleep 2
  fi
}

install_cockpit() {
  if [ "$IS_INSTALLED" = true ]; then
    echo -e "\n${WARN}⚠️  Already installed!${NC}"; sleep 2
    return
  fi
  echo -e "\n${INFO}🚀 Installing Cockpit...${NC}"
  docker run -d --name cockpit --hostname Zensei --privileged --net=host --cgroupns=host -v /sys/fs/cgroup:/sys/fs/cgroup:rw nobitaa/cockpit:latest
  echo -e "${SUCCESS}✅ Installed & Started!${NC}"
  sleep 2
}

uninstall_cockpit() {
  echo -e "\n${DANGER}🗑  Removing Container...${NC}"
  docker stop cockpit &>/dev/null
  docker rm cockpit &>/dev/null
  docker rmi nobitaa/cockpit:latest &>/dev/null

  echo -e "${SUCCESS}✨ Container Cleaned.${NC}"
  sleep 2
}

delete_image() {
  uninstall_cockpit
  echo -e "${MAGENTA}📦 Deleting Docker Image...${NC}"
  docker rmi nobitaa/cockpit:latest &>/dev/null
  echo -e "${SUCCESS}✅ Image Wiped.${NC}"
  sleep 2
}

login_info() {
  clear
  get_ips
  echo -e "${ACCENT}┌──────────────────────────────────────────┐${NC}"
  echo -e "${ACCENT}│${NC}  ${BOLD}🔑 ACCESS CREDENTIALS${NC}                ${ACCENT}│${NC}"
  echo -e "${ACCENT}├──────────────────────────────────────────┤${NC}"
  echo -e "   ${BOLD}Username:${NC} ${SUCCESS}root"
  echo -e "   ${BOLD}Password:${NC} ${SUCCESS}root123"
  echo -e "   ${INFO}Public:${NC}    $PUBLIC_IP":9090
  echo -e "   ${INFO}Tailscale:${NC} $TAILSCALE_IP":9090
  echo -e "   ${INFO}Local:${NC}     $LOCAL_IP":9090
  echo -e "${ACCENT}└──────────────────────────────────────────┘${NC}"
  read -p " Press [Enter] to return..."
}

# --- Main Menu Loop ---
while true; do
  clear
  get_status
  get_ips

  echo -e "${ACCENT}╔══════════════════════════════════════════╗${NC}"
  echo -e "${ACCENT}║${NC}       ${BOLD}💎 COCKPIT MANAGER PRO 💎${NC}          ${ACCENT}║${NC}"
  echo -e "${ACCENT}╚══════════════════════════════════════════╝${NC}"
  echo -e "  ${BOLD}STATUS:${NC}    $STATUS"
  echo -e "  ${BOLD}LOCAL IP:${NC}  $LOCAL_IP"
  echo -e "${ACCENT}────────────────────────────────────────────${NC}"
  echo -e "  ${BOLD}[1]${NC} ${SUCCESS}Install${NC}"
  echo -e "  ${BOLD}[2]${NC} ${INFO}Turn ON${NC}"
  echo -e "  ${BOLD}[3]${NC} ${DANGER}Turn OFF${NC}"
  echo -e "  ${BOLD}[4]${NC} ${MAGENTA}Restart${NC}"
  echo -e "  ${BOLD}[5]${NC} Uninstall"
  echo -e "  ${BOLD}[6]${NC} ${WARN}Login Info${NC}"
  echo -e "  ${BOLD}[0]${NC} Exit"
  echo ""
  echo -ne "  ${ACCENT}Selection ➜  ${NC}"
  read choice

  case $choice in
    1) install_cockpit ;;
    2) toggle_on ;;
    3) toggle_off ;;
    4) restart_cockpit ;;
    5) uninstall_cockpit ;;
    6) login_info ;;
    0) echo -e "${INFO}Bye! 👋${NC}"; exit ;;
    *) echo -e "${DANGER}❌ Invalid Selection${NC}"; sleep 1 ;;
  esac
done
