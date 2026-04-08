#!/bin/bash

# ================= COLORS & STYLING =================
R="\e[31m"; G="\e[32m"; Y="\e[33m"
B="\e[34m"; M="\e[35m"; C="\e[36m"
W="\e[97m"; N="\e[0m"
BOLD="\e[1m"; DIM="\e[2m"

# ================= ANIMATION =================
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⣾⣽⣻⢿⡿⣟⣯⣷'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c] " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# ================= UI FUNCTIONS =================
header() {
  clear
  echo -e "${M}${BOLD}"
  echo "╠════════════════════════════════════════════════════════════════════════╣"
  echo "║                    🚀 Pterodactyl Blueprint Installer                  ║"
  echo "║              Auto Installation • No Menu • Straight Process            ║"
  echo "╚════════════════════════════════════════════════════════════════════════╝"
  echo -e "${N}"
}

step() {
    echo -e "\n${C}${BOLD}▶${N} ${W}${BOLD}$1${N}"
    echo -e "  ${DIM}╰─ ${W}$2${N}"
}

ok() {
    echo -e "  ${G}✓${N} ${G}$1${N}"
}

warn() {
    echo -e "  ${Y}⚠${N} ${Y}$1${N}"
}

fail() {
    echo -e "  ${R}✗${N} ${R}$1${N}"
    echo -e "${Y}Continuing in 3 seconds...${N}"
    sleep 3
}

info() {
    echo -e "  ${B}ℹ${N} ${B}$1${N}"
}

divider() {
    echo -e "${M}${DIM}────────────────────────────────────────────────────────────────${N}"
}

# ================= CHECK ROOT =================
if [ "$EUID" -ne 0 ]; then
  echo -e "${R}${BOLD}"
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║                     PERMISSION DENIED                        ║"
  echo "╠══════════════════════════════════════════════════════════════╣"
  echo "║  Please run as root: ${W}sudo $0${R}${BOLD}                           ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
  echo -e "${N}"
  exit 1
fi

# ================= START =================
header

step "System Check" "Verifying environment and prerequisites"
if [ ! -d "/var/www/pterodactyl" ]; then
    fail "Pterodactyl not found at /var/www/pterodactyl"
    exit 1
fi
ok "Pterodactyl panel found"
ok "Running as root"
divider

# ================= UPDATE PANEL =================
step "Panel Update" "Updating Pterodactyl to latest version"
cd /var/www/pterodactyl || fail "Failed to access panel directory"

info "Entering maintenance mode"
php artisan down

info "Downloading panel update"
(curl -L https://github.com/pterodactyl/panel/releases/download/v1.11.11/panel.tar.gz | tar -xzv) &
spinner $!

info "Setting permissions"
chmod -R 755 storage/* bootstrap/cache

info "Installing dependencies"
COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader

info "Clearing caches"
php artisan view:clear
php artisan config:clear

info "Running migrations"
php artisan migrate --seed --force

info "Setting ownership"
chown -R www-data:www-data /var/www/pterodactyl/*

info "Restarting queue"
php artisan queue:restart

info "Exiting maintenance mode"
php artisan up

ok "Panel updated successfully"
divider

# ================= INSTALL DEPENDENCIES =================
step "Dependencies" "Installing system dependencies"
apt update -y
apt install -y curl wget unzip ca-certificates git gnupg zip lsb-release
ok "System dependencies installed"
divider

# ================= SET DIRECTORY =================
export PTERODACTYL_DIRECTORY=/var/www/pterodactyl
cd "$PTERODACTYL_DIRECTORY" || fail "Failed to access panel directory"

# ================= DOWNLOAD BLUEPRINT =================
step "Blueprint" "Downloading Blueprint Framework"
info "Fetching latest release..."
LATEST_URL=$(curl -s https://api.github.com/repos/BlueprintFramework/framework/releases/latest | grep 'browser_download_url.*release.zip' | cut -d '"' -f 4)
VERSION=$(curl -s https://api.github.com/repos/BlueprintFramework/framework/releases/latest | grep '"tag_name"' | cut -d '"' -f 4)

info "Version: $VERSION"
wget "$LATEST_URL" -O "$PTERODACTYL_DIRECTORY/release.zip"

info "Extracting files"
unzip -o release.zip
ok "Blueprint $VERSION downloaded & extracted"
divider

# ================= INSTALL NODE.JS =================
step "Node.js" "Installing Node.js 20.x"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" > /etc/apt/sources.list.d/nodesource.list

apt update -y
apt install -y nodejs

info "Node.js $(node --version)"
info "npm $(npm --version)"
ok "Node.js installed"
divider

# ================= INSTALL YARN & DEPS =================
step "Yarn & Dependencies" "Installing build tools"
npm i -g yarn
yarn install
ok "Build dependencies installed"
divider

# ================= CONFIGURATION =================
step "Configuration" "Setting up Blueprint"
cat <<EOF > "$PTERODACTYL_DIRECTORY/.blueprintrc"
# Blueprint Configuration
WEBUSER="www-data"
OWNERSHIP="www-data:www-data"
USERSHELL="/bin/bash"
INSTALL_DATE="$(date)"
INSTALL_VERSION="$VERSION"
EOF
ok "Configuration created"
divider

# ================= PERMISSIONS =================
step "Permissions" "Setting file permissions"
chmod +x "$PTERODACTYL_DIRECTORY/blueprint.sh"
chown -R www-data:www-data "$PTERODACTYL_DIRECTORY"
chmod -R 755 storage bootstrap/cache
ok "Permissions set"
divider

# ================= LAUNCH BLUEPRINT =================
step "Finalization" "Launching Blueprint installer"
echo -e "${Y}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║              BLUEPRINT INSTALLER STARTING                    ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${N}"

bash "$PTERODACTYL_DIRECTORY/blueprint.sh"

# ================= COMPLETION =================
echo -e "\n${G}${BOLD}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                INSTALLATION COMPLETE!                        ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  ✅ Panel Updated                                            ║"
echo "║  ✅ Blueprint Installed                                      ║"
echo "║  ✅ Dependencies Installed                                   ║"
echo "║  ✅ Permissions Fixed                                        ║"
echo "║                                                              ║"
echo "║  The Blueprint UI is now ready!                              ║"
echo "║  Access your panel to see the changes.                       ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${N}"

echo -e "${C}Next steps:${N}"
echo -e "  ${W}1.${N} Clear your browser cache"
echo -e "  ${W}2.${N} Visit your panel URL"
echo -e "  ${W}3.${N} Enjoy the new Blueprint interface!"
echo -e "\n${Y}Made with ❤️  for the Pterodactyl community${N}\n"
