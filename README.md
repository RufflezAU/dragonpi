# 🐉 DragonPi — Cybersecurity Toolkit for Raspberry Pi

A complete, ready-to-deploy cybersecurity platform for Raspberry Pi 4/5. Web dashboard, AI chatbot, 40+ tools, one-click launchers — everything a security professional needs.

## 📡 Quick Install

```bash
curl -sSL https://raw.githubusercontent.com/YOU/dragonpi/main/install.sh | sudo bash
```

After install, open `http://dragonpi.local` in your browser.

## 🖥 Features

| Feature | Description |
|---------|-------------|
| **Web Dashboard** | Homer-based dashboard with 50+ tools in 11 categories |
| **AI Chatbot** | OpenCode Go + DeepSeek V4 Pro — chat to run tools, scan networks, manage system |
| **Web Terminal** | ttyd — full bash terminal in your browser |
| **One-Click Launchers** | Click any tool → terminal opens with beginner-friendly guide |
| **System Monitor** | Live CPU/RAM/Disk/Temp in sidebar |
| **RSS News Ticker** | Scrolling cybersecurity headlines from 9 sources |
| **Cockpit** | System management web UI on port 9090 |

## 🛠 Tools Included (40+)

| Category | Tools |
|----------|-------|
| **Vulnerability Scanning** | Nmap (50 CVE scripts), Nikto, SQLmap, SearchSploit |
| **Network Scanning** | Nmap, Masscan, Netdiscover, Amass, Subfinder, TheHarvester |
| **Network Analysis** | tcpdump, tshark, Netcat, Socat |
| **Password Attacks** | Hashcat, John, Hydra, Crunch, CeWL |
| **Windows/AD** | Enum4linux, SMB Client, Impacket, Certipy, BloodHound, Coercer |
| **Web Application** | Gobuster, ffuf, Wfuzz, Dirb, WhatWeb, Wafw00f |
| **MITM & Tunneling** | Mitmproxy, Ettercap, Chisel, SSHuttle, Proxychains |
| **Forensics** | Autopsy (Web UI), Binwalk, Foremost, ExifTool, Steghide, dc3dd |
| **Wireless** | Aircrack-ng, Wifite, Reaver, PixieWPS, airbase-ng, Horst |

## 🏗 Architecture

```
dragonpi.local (port 80)
├── Homer Dashboard    → /var/www/homer
├── DragonAI Chatbot   → /chat → Flask :5000 → OpenCode Go
├── Web Terminal       → :7681 → ttyd
├── Cockpit            → :9090
├── RSS Feed           → /rss → Flask proxy
└── Tool Launcher      → /term/TOOL → auto-opens terminal
```

## 📁 File Structure

```
dragonpi/
├── install.sh              # One-line installer
├── chatbot/
│   ├── app.py              # Flask backend (chatbot + APIs)
│   └── templates/
│       └── index.html      # Chat UI
├── homer/
│   ├── config.yml          # Dashboard configuration
│   └── index.html          # Homer base (widgets injected)
├── nginx/
│   └── dragonpi.conf       # Nginx reverse proxy
├── services/
│   ├── chatbot.service     # DragonAI systemd unit
│   └── ttyd.service        # Web terminal systemd unit
├── scripts/
│   ├── dragonpi-shell      # Terminal wrapper (auto-runs tools)
│   └── guides/             # Beginner guides for each tool
└── .gitignore
```

## 🔧 Development

```bash
git clone https://github.com/YOU/dragonpi.git
cd dragonpi
sudo ./install.sh
```

To update an existing install:
```bash
cd /opt/dragonpi
git pull
sudo ./install.sh
```

## 📋 Requirements

- Raspberry Pi 4 or 5 (4GB+ RAM recommended)
- Raspberry Pi OS (Debian 12/13, 64-bit)
- 32GB+ SD card
- OpenCode Go subscription (for AI chatbot)

## 📜 License

MIT — Use responsibly. Only test systems you own or have permission to test.
