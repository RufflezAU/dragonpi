#!/bin/bash
# ================================================================
#  DragonPi — One-Line Installer
#  curl -sSL https://raw.githubusercontent.com/RufflezAU/dragonpi/main/install.sh | sudo bash
# ================================================================
set -e

echo "🐉 DragonPi Installer"
echo "===================="

# Config (edit these!)
PASSWORD="${PASSWORD:-changeme}"
USERNAME="${USERNAME:-dragonpi}"
HOSTNAME="${HOSTNAME:-DragonPi}"

# Install deps
echo "Installing dependencies..."
sudo apt update -qq && sudo apt upgrade -y -qq
sudo apt install -y -qq nginx python3-pip python3-venv git curl wget unzip \
    avahi-daemon avahi-utils ufw ttyd cockpit htop btop tmux jq

# Install pip deps
sudo pip install flask requests pyyaml feedparser --break-system-packages

# Install pentest + report deps
sudo pip install reportlab jinja2 --break-system-packages
# zapcli pulls in old click/urllib3/chardet that break Flask — install zapcli
# then immediately upgrade the broken deps back to compatible versions
sudo pip install zapcli --break-system-packages 2>/dev/null || true
sudo pip install --break-system-packages --upgrade "click>=8.0.0" "urllib3>=1.26.2" "requests>=2.29.0" "chardet>=4.0"

# Set hostname
sudo hostnamectl set-hostname "$HOSTNAME"

# Repo dir (script lives at repo root)
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

# Deploy dashboard config + nginx config
sudo mkdir -p /opt/dragonpi/dashboard
sudo cp "$REPO_DIR/dashboard/config.yml" /opt/dragonpi/dashboard/config.yml
sudo cp "$REPO_DIR/nginx/dragonpi.conf" /etc/nginx/sites-available/dragonpi
sudo ln -sf /etc/nginx/sites-available/dragonpi /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Deploy chatbot (dashboard engine + chat + podcast + pentest)
sudo mkdir -p /opt/dragonpi/chatbot/templates /opt/dragonpi/reports /opt/dragonpi/pentest-jobs
sudo cp "$REPO_DIR/chatbot/app.py" /opt/dragonpi/chatbot/app.py
sudo cp "$REPO_DIR/chatbot/pentest.py" /opt/dragonpi/chatbot/pentest.py
sudo cp "$REPO_DIR/chatbot/templates/dashboard.html" /opt/dragonpi/chatbot/templates/dashboard.html
sudo cp "$REPO_DIR/chatbot/templates/index.html" /opt/dragonpi/chatbot/templates/index.html
sudo cp "$REPO_DIR/chatbot/templates/podcast.html" /opt/dragonpi/chatbot/templates/podcast.html
sudo cp "$REPO_DIR/chatbot/templates/pentest.html" /opt/dragonpi/chatbot/templates/pentest.html
sudo cp "$REPO_DIR/chatbot/templates/report_template.html" /opt/dragonpi/chatbot/templates/report_template.html
sudo cp "$REPO_DIR/scripts/dragonpi-shell" /usr/local/bin/dragonpi-shell
sudo cp "$REPO_DIR/scripts/dragonpi-screenshot" /usr/local/bin/dragonpi-screenshot
sudo cp "$REPO_DIR/scripts/guides/"* /usr/local/bin/ 2>/dev/null || true
sudo chmod +x /usr/local/bin/dragonpi-shell /usr/local/bin/dragonpi-screenshot /usr/local/bin/dragonpi-guide-*

# Install services
sudo cp "$REPO_DIR/services/chatbot.service" /etc/systemd/system/
sudo cp "$REPO_DIR/services/ttyd.service" /etc/systemd/system/
sudo cp "$REPO_DIR/services/autopsy.service" /etc/systemd/system/
sudo cp "$REPO_DIR/services/dragonpi-screenshot.service" /etc/systemd/system/
sudo cp "$REPO_DIR/services/dragonpi-screenshot.timer" /etc/systemd/system/
sudo sed -i "s/YOUR_PASSWORD_HERE/$PASSWORD/g" /etc/systemd/system/ttyd.service
# Autopsy evidence locker must exist and be owned by dragonpi, or the
# service crashes on first boot with "Can't open log: autopsy.log" (exit 13).
sudo mkdir -p /var/lib/autopsy
sudo chown dragonpi:dragonpi /var/lib/autopsy
# Screenshots directory for auto-refreshing dashboard screenshot
sudo mkdir -p /opt/dragonpi/screenshots
sudo chown dragonpi:dragonpi /opt/dragonpi/screenshots
sudo systemctl daemon-reload
sudo systemctl enable --now nginx chatbot ttyd autopsy cockpit dragonpi-screenshot.timer

# Install security tools
echo "Installing security tools..."
sudo apt install -y -qq nmap masscan netdiscover nikto sqlmap dirb gobuster ffuf wfuzz \
    whatweb wafw00f aircrack-ng hashcat john hydra tcpdump tshark crunch cewl \
    searchsploit enum4linux smbclient binwalk foremost exiftool steghide \
    ettercap-text-only proxychains4 sshuttle socat netcat-openbsd \
    horst wifite reaver pixiewps hcxdumptool hcxtools hostapd dnsmasq \
    autopsy dc3dd sleuthkit python3-plaso \
    openjdk-21-jdk-headless

# Install OWASP ZAP (cross-platform core from GitHub releases)
if [ ! -f /opt/zap/zap.sh ]; then
    echo "Installing OWASP ZAP 2.17.0..."
    wget -q "https://github.com/zaproxy/zaproxy/releases/download/v2.17.0/ZAP_2.17.0_Linux.tar.gz" -O /tmp/zap.tar.gz
    sudo mkdir -p /opt/zap
    sudo tar -xzf /tmp/zap.tar.gz -C /opt/zap --strip-components=1
    sudo ln -sf /opt/zap/zap.sh /usr/local/bin/zap.sh
    rm -f /tmp/zap.tar.gz
fi

# Install pip tools
sudo pip install --break-system-packages \
    theHarvester impacket certipy-ad bloodhound coercer pwncat-cs mitmproxy

# Install Go tools (amass, subfinder, chisel)
sudo apt install -y -qq golang-go
go install github.com/owasp-amass/amass/v4/...@latest 2>/dev/null || true
go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest 2>/dev/null || true
sudo cp /home/dragonpi/go/bin/* /usr/local/bin/ 2>/dev/null || true

# Chisel binary
wget -q "https://github.com/jpillora/chisel/releases/download/v1.10.1/chisel_1.10.1_linux_arm64.gz" -O /tmp/chisel.gz
gunzip -f /tmp/chisel.gz && sudo mv /tmp/chisel /usr/local/bin/chisel && sudo chmod +x /usr/local/bin/chisel

# Firewall
sudo ufw --force reset >/dev/null 2>&1
sudo ufw default deny incoming && sudo ufw default allow outgoing
for port in 80 443 22 7681 9090 9999 40000:50000; do sudo ufw allow $port/tcp; done
sudo ufw allow 53/udp && sudo ufw allow 5353/udp
sudo ufw --force enable

# Permissions
sudo chown -R dragonpi:dragonpi /opt/dragonpi 2>/dev/null || true
sudo chown -R dragonpi:dragonpi /opt/dragonpi/reports /opt/dragonpi/pentest-jobs 2>/dev/null || true
sudo usermod -aG wireshark dragonpi 2>/dev/null || true

# Restart
sudo nginx -t && sudo systemctl restart nginx chatbot ttyd

echo ""
echo "✅ DragonPi installed!"
echo "   Dashboard: http://dragonpi.local"
echo "   AI Chat:   http://dragonpi.local/chat"
echo "   Terminal:  http://dragonpi.local:7681"
echo ""
echo "⚠️  Set your OpenCode API key in /opt/dragonpi/chatbot/.env"
echo "   Then: sudo systemctl restart chatbot"
