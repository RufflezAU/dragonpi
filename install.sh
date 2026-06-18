#!/bin/bash
# ================================================================
#  DragonPi — One-Line Installer
#  curl -sSL https://raw.githubusercontent.com/YOU/dragonpi/main/install.sh | sudo bash
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

# Set hostname
sudo hostnamectl set-hostname "$HOSTNAME"

# Deploy dashboard (Homer)
HOMER_VER=$(curl -s https://api.github.com/repos/bastienwirtz/homer/releases/latest | grep tag_name | cut -d '"' -f 4)
wget -q "https://github.com/bastienwirtz/homer/releases/download/${HOMER_VER}/homer.zip" -O /tmp/homer.zip
sudo unzip -q /tmp/homer.zip -d /var/www/homer
rm /tmp/homer.zip

# Copy our files
REPO_DIR="$(dirname "$0")"
sudo cp "$REPO_DIR/homer/config.yml" /var/www/homer/assets/config.yml
sudo cp "$REPO_DIR/nginx/dragonpi.conf" /etc/nginx/sites-available/dragonpi
sudo ln -sf /etc/nginx/sites-available/dragonpi /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Deploy chatbot
sudo mkdir -p /opt/dragonpi/chatbot/templates
sudo cp "$REPO_DIR/chatbot/app.py" /opt/dragonpi/chatbot/app.py
sudo cp "$REPO_DIR/chatbot/templates/index.html" /opt/dragonpi/chatbot/templates/index.html
sudo cp "$REPO_DIR/scripts/dragonpi-shell" /usr/local/bin/dragonpi-shell
sudo cp "$REPO_DIR/scripts/guides/"* /usr/local/bin/ 2>/dev/null || true
sudo chmod +x /usr/local/bin/dragonpi-shell /usr/local/bin/dragonpi-guide-*

# Install services
sudo cp "$REPO_DIR/services/chatbot.service" /etc/systemd/system/
sudo cp "$REPO_DIR/services/ttyd.service" /etc/systemd/system/
sudo sed -i "s/YOUR_PASSWORD_HERE/$PASSWORD/g" /etc/systemd/system/ttyd.service
sudo systemctl daemon-reload
sudo systemctl enable --now nginx chatbot ttyd cockpit

# Install security tools
echo "Installing security tools..."
sudo apt install -y -qq nmap masscan netdiscover nikto sqlmap dirb gobuster ffuf wfuzz \
    whatweb wafw00f aircrack-ng hashcat john hydra tcpdump tshark crunch cewl \
    searchsploit enum4linux smbclient binwalk foremost exiftool steghide \
    ettercap-text-only proxychains4 sshuttle socat netcat-openbsd \
    horst wifite reaver pixiewps hcxdumptool hcxtools hostapd dnsmasq \
    autopsy dc3dd sleuthkit python3-plaso

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
