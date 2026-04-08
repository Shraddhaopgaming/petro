#!/usr/bin/env bash
# ==================================================
#  NOBITA SECURE LOADER | BOOTSTRAP SYSTEM (FIXED)
# ==================================================
set -euo pipefail

# --- COLORS & STYLES ---
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_RED='\033[1;31m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_BLUE='\033[1;34m'
C_PURPLE='\033[1;35m'
C_CYAN='\033[1;36m'
C_WHITE='\033[1;37m'
C_GRAY='\033[1;90m'

# --- CONFIG ---
URL="https://run.nobitapro.online"
HOST="run.nobitapro.online"
NETRC="${HOME}/.netrc"

# --- CREDENTIALS ---
IP="65.0.86.121"
LOCL_IP="10.1.0.29"
USER_LOGIN="nobita.dev"      # Mapped from logic below
USER_PASS="admin@codinghub.host" # Mapped from logic below

# --- UI FUNCTIONS ---
draw_header() {
    clear
    echo -e "${C_PURPLE}╔════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_PURPLE}║${C_RESET} ${C_BOLD}${C_WHITE}NOBITA CLOUD UPLINK${C_RESET} ${C_GRAY}::${C_RESET} ${C_CYAN}SECURE BOOTSTRAP${C_RESET}                 ${C_PURPLE}║${C_RESET}"
    echo -e "${C_PURPLE}╚════════════════════════════════════════════════════════════╝${C_RESET}"
    echo -e "${C_GRAY}  Target Host: ${C_WHITE}$HOST${C_RESET}"
    echo ""
}

msg_info() { echo -e "  ${C_BLUE}➜${C_RESET} $1"; }
msg_ok()   { echo -e "  ${C_GREEN}✔${C_RESET} $1"; }
msg_err()  { echo -e "  ${C_RED}✖${C_RESET} $1"; }

# Spinner Animation
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# --- MAIN LOGIC ---
draw_header

# 1. Dependency Check
if ! command -v curl >/dev/null 2>&1; then
    msg_err "Dependency Missing: curl"
    exit 1
fi

# 2. Configure Auth
msg_info "Configuring Secure Credentials..."

# Create/Secure file
touch "$NETRC"
chmod 600 "$NETRC"

# Clean old entries for this specific host
tmpfile="$(mktemp)"
grep -vE "^[[:space:]]*machine[[:space:]]+${HOST}([[:space:]]+|$)" "$NETRC" > "$tmpfile" || true
mv "$tmpfile" "$NETRC"

# Inject Credentials
# Note: Using variables defined above. 
# Based on your comments, it seems you want $IP as login and $LOCL_IP as password?
# If you actually meant user="nobita.dev", switch the variables below.
{
    printf 'machine %s ' "$HOST"
    printf 'login %s ' "$IP"
    printf 'password %s\n' "$LOCL_IP"
} >> "$NETRC"

msg_ok "Authentication Token Generated."

# 3. Download Payload
script_file="$(mktemp)"
cleanup() { rm -f "$script_file"; }
trap cleanup EXIT

echo -ne "  ${C_CYAN}➜${C_RESET} Establishing Downlink... "

# Run curl in background to show spinner
# -L follows redirects, -A mimics browser to avoid some 403s
(curl -fsSL -A "Mozilla/5.0" --netrc -o "$script_file" "$URL") &
spinner $!
wait $!
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo -e " ${C_GREEN}OK${C_RESET}"
    msg_ok "Payload Received Successfully."
    echo ""
    echo -e "${C_PURPLE}  [ SYSTEM ]${C_RESET} Executing Remote Script..."
    sleep 1
    
    # Handover control to the downloaded script
    bash "$script_file"
else
    echo -e " ${C_RED}FAIL${C_RESET}"
    msg_err "Download Failed. Check network or credentials."
    
    # Debug hint
    echo -e "${C_GRAY}  Debug Info: Ensure IPs in .netrc match server expectations.${C_RESET}"
    exit 1
fi
