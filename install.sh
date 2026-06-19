#!/bin/bash
# ================================================================
#  DragonPi — One-Click Installer (Raspberry Pi 4/5, Debian 12/13)
#  curl -sSL https://raw.githubusercontent.com/RufflezAU/dragonpi/main/install.sh | sudo bash
# ================================================================
set -e

echo "🐉 DragonPi Installer"
echo "===================="

# ── Config (override via env) ──
PASSWORD="${PASSWORD:-changeme}"
USERNAME="${USERNAME:-dragonpi}"
HOSTNAME="${HOSTNAME:-DragonPi}"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── System deps ──
echo ""
echo "📦 Installing system packages..."
apt update -qq && apt upgrade -y -qq
apt install -y -qq \
    nginx python3-pip python3-venv git curl wget unzip jq \
    avahi-daemon avahi-utils ufw ttyd cockpit htop btop tmux \
    dnsutils golang-go apt-transport-https ca-certificates

# ── Tailscale (optional remote access — skip with TAILSCALE=0) ──
if [ "${TAILSCALE:-1}" != "0" ] && ! command -v tailscale &>/dev/null; then
    echo "🔗 Installing Tailscale for remote access..."
    curl -fsSL https://tailscale.com/install.sh | sh
    echo "   Run 'sudo tailscale up' to connect after install."
fi

# ── Python deps ──
echo ""
echo "🐍 Installing Python packages..."
pip install --break-system-packages -q \
    flask requests pyyaml feedparser reportlab jinja2

# ZAP CLI (then fix its broken deps)
pip install --break-system-packages -q zapcli 2>/dev/null || true
pip install --break-system-packages -q --upgrade \
    "click>=8.0.0" "urllib3>=1.26.2" "requests>=2.29.0" "chardet>=4.0"

# ── Security tools (apt) ──
echo ""
echo "🔧 Installing security tools..."
apt install -y -qq \
    nmap masscan netdiscover nikto sqlmap dirb gobuster ffuf wfuzz \
    whatweb wafw00f aircrack-ng hashcat john hydra tcpdump tshark crunch cewl \
    searchsploit enum4linux smbclient binwalk foremost exiftool steghide \
    ettercap-text-only proxychains4 sshuttle socat netcat-openbsd \
    horst autopsy dc3dd sleuthkit \
    testssl.sh sslscan lynis chromium \
    openjdk-21-jdk-headless

# ── Go tools (nuclei, naabu, httpx, dalfox, amass, subfinder) ──
echo ""
echo "🔧 Installing Go-based tools (this may take a few minutes)..."
export PATH="$PATH:/home/$USERNAME/go/bin"

_go_install() {
    local pkg="$1" bin="$2"
    echo "  → ${bin:-$pkg}..."
    go install "$pkg@latest" 2>/dev/null && \
        sudo cp "/home/$USERNAME/go/bin/${bin:-$pkg}" /usr/local/bin/ 2>/dev/null || \
        echo "    (skipped — may need manual install)"
}

_go_install "github.com/projectdiscovery/nuclei/v2/cmd/nuclei" "nuclei"
_go_install "github.com/projectdiscovery/naabu/v2/cmd/naabu" "naabu"
_go_install "github.com/projectdiscovery/httpx/cmd/httpx" "httpx"
_go_install "github.com/hahwul/dalfox/v2" "dalfox"
_go_install "github.com/owasp-amass/amass/v4/..." "amass"
_go_install "github.com/projectdiscovery/subfinder/v2/cmd/subfinder" "subfinder"

# Download nuclei templates (300MB — background)
echo "  → nuclei templates (background)..."
nohup nuclei -update-templates > /dev/null 2>&1 &

# ── theHarvester + impacket + related pip tools ──
echo ""
echo "🔧 Installing Python security tools..."
pip install --break-system-packages -q \
    theHarvester impacket certipy-ad bloodhound coercer pwncat-cs mitmproxy

# ── chisel (pre-built binary for ARM) ──
echo ""
echo "🔧 Installing chisel..."
wget -q "https://github.com/jpillora/chisel/releases/download/v1.10.1/chisel_1.10.1_linux_arm64.gz" -O /tmp/chisel.gz
gunzip -f /tmp/chisel.gz && mv /tmp/chisel /usr/local/bin/chisel && chmod +x /usr/local/bin/chisel

# ── OWASP ZAP 2.17.0 ──
if [ ! -f /opt/zap/zap.sh ]; then
    echo ""
    echo "🔧 Installing OWASP ZAP 2.17.0..."
    wget -q "https://github.com/zaproxy/zaproxy/releases/download/v2.17.0/ZAP_2.17.0_Linux.tar.gz" -O /tmp/zap.tar.gz
    mkdir -p /opt/zap
    tar -xzf /tmp/zap.tar.gz -C /opt/zap --strip-components=1
    ln -sf /opt/zap/zap.sh /usr/local/bin/zap.sh
    rm -f /tmp/zap.tar.gz
fi

# ── Playwright (for dashboard screenshots) ──
echo ""
echo "🔧 Installing Playwright for screenshots..."
pip install --break-system-packages -q playwright
python3 -m playwright install chromium 2>/dev/null || echo "  (playwright chromium skipped — will use system chromium)"

# ── Hostname ──
hostnamectl set-hostname "$HOSTNAME" 2>/dev/null || true

# ── Deploy files ──
echo ""
echo "📂 Deploying DragonPi files..."

# Create directories
mkdir -p /opt/dragonpi/chatbot/templates /opt/dragonpi/dashboard
mkdir -p /opt/dragonpi/reports /opt/dragonpi/pentest-jobs
mkdir -p /opt/dragonpi/screenshots /opt/dragonpi/.backups

# Dashboard + nginx
cp "$REPO_DIR/dashboard/config.yml" /opt/dragonpi/dashboard/config.yml
cp "$REPO_DIR/nginx/dragonpi.conf" /etc/nginx/sites-available/dragonpi
ln -sf /etc/nginx/sites-available/dragonpi /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Chatbot (Flask app + templates)
cp "$REPO_DIR/chatbot/app.py" /opt/dragonpi/chatbot/app.py
cp "$REPO_DIR/chatbot/pentest.py" /opt/dragonpi/chatbot/pentest.py
for tmpl in dashboard index podcast pentest report_template; do
    cp "$REPO_DIR/chatbot/templates/${tmpl}.html" /opt/dragonpi/chatbot/templates/ 2>/dev/null || true
done

# Scripts
cp "$REPO_DIR/scripts/dragonpi-shell" /usr/local/bin/dragonpi-shell
cp "$REPO_DIR/scripts/dragonpi-update" /usr/local/bin/dragonpi-update
cp "$REPO_DIR/scripts/dragonpi-screenshot" /usr/local/bin/dragonpi-screenshot
cp "$REPO_DIR/scripts/guides/"* /usr/local/bin/ 2>/dev/null || true
chmod +x /usr/local/bin/dragonpi-*

# Services
cp "$REPO_DIR/services/chatbot.service" /etc/systemd/system/
cp "$REPO_DIR/services/ttyd.service" /etc/systemd/system/
cp "$REPO_DIR/services/autopsy.service" /etc/systemd/system/
cp "$REPO_DIR/services/dragonpi-screenshot.service" /etc/systemd/system/
cp "$REPO_DIR/services/dragonpi-screenshot.timer" /etc/systemd/system/
sed -i "s/YOUR_PASSWORD_HERE/$PASSWORD/g" /etc/systemd/system/ttyd.service

# Autopsy working dir (must exist or service crashes)
mkdir -p /var/lib/autopsy

# ── OpenCode (AI backend) ──
echo ""
echo "🤖 Installing OpenCode Go..."
if [ ! -f /home/$USERNAME/.opencode/bin/opencode ]; then
    curl -fsSL https://opencode.ai/install.sh | bash 2>/dev/null || \
        echo "  ⚠️ OpenCode install failed — install manually: curl -fsSL https://opencode.ai/install.sh | bash"
fi

# ── Ownership ──
echo ""
echo "🔒 Setting permissions..."
chown -R $USERNAME:$USERNAME /opt/dragonpi 2>/dev/null || true
chown -R $USERNAME:$USERNAME /opt/dragonpi/reports /opt/dragonpi/pentest-jobs 2>/dev/null || true
chown -R $USERNAME:$USERNAME /opt/dragonpi/screenshots /var/lib/autopsy 2>/dev/null || true
chown -R $USERNAME:$USERNAME /home/$USERNAME/go 2>/dev/null || true

# ── Firewall ──
echo ""
echo "🛡 Configuring firewall..."
ufw --force reset >/dev/null 2>&1
ufw default deny incoming && ufw default allow outgoing
for port in 80 443 22 7681 9090 9999; do ufw allow $port/tcp; done
ufw allow 53/udp && ufw allow 5353/udp
ufw --force enable

# ── Enable & start services ──
echo ""
echo "🚀 Starting services..."
systemctl daemon-reload
systemctl enable --now nginx chatbot ttyd autopsy cockpit dragonpi-screenshot.timer 2>/dev/null || true

# Test nginx config and reload
nginx -t && systemctl reload nginx

# ── Done ──
echo ""
echo "══════════════════════════════════════════════"
echo "  🐉 DragonPi installed!"
echo ""
echo "  Dashboard:  http://dragonpi.local"
echo "  Chat:       http://dragonpi.local/chat"
echo "  Pentest:    http://dragonpi.local/pentest"
echo "  Terminal:   http://dragonpi.local/terminal/"
echo "  Cockpit:    https://dragonpi.local:9090"
echo ""
echo "  ⚠️  Configure your OpenCode API key:"
echo "     Create /home/$USERNAME/.opencode/config.json"
echo "     See: https://opencode.ai/docs"
echo "══════════════════════════════════════════════"
