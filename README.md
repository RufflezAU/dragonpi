# 🐉 DragonPi — Cybersecurity Toolkit for Raspberry Pi

> ⚠️ **Vibe Coded Disclaimer**: This project was built entirely with AI assistance (OpenCode Go + DeepSeek) as an experiment to see what could be accomplished. **Use at your own risk.** It is 100% vibe coded — no manual coding, no guarantees, no warranties. If it breaks, roll it back. If it works, you're welcome.

A complete, ready-to-deploy cybersecurity platform for Raspberry Pi 4/5. Web dashboard, AI chatbot, 40+ tools, one-click launchers, automated pentesting — everything a security professional needs.

## 📡 Quick Install

```bash
curl -sSL https://raw.githubusercontent.com/RufflezAU/dragonpi/main/install.sh | sudo bash
```

After install, open `http://dragonpi.local` in your browser.

> 💡 **Recommended: Configure OpenCode API Key**
> 
> The chatbot uses `deepseek-v4-flash-free` by default (no key needed).
> For better results — especially pentest self-healing and complex analysis —
> add a Pro API key for `deepseek-v4-pro`. The system auto-falls back to free
> if Pro is unavailable.
> 
> ```bash
> mkdir -p ~/.opencode
> cat > ~/.opencode/config.json << 'EOF'
> {
>   "providers": {
>     "opencode-go": {
>       "api_key": "YOUR_API_KEY_HERE"
>     }
>   }
> }
> EOF
> sudo systemctl restart chatbot
> ```
> 
> Get a key at [opencode.ai](https://opencode.ai). The free tier works without any key.

## 🖥 Features

| Feature | Description |
|---------|-------------|
| **Web Dashboard** | Custom Flask dashboard engine with 50+ tools in 11 categories, live system stats, threat intel |
| **AI Chatbot** | OpenCode-powered AI assistant — chat to run tools, scan networks, manage the system. Auto-falls back to free model if Pro unavailable |
| **Automated Pentesting** | 24+ tool pentest pipeline (external + internal). Per-tool checkboxes, DAST vulnerability scanning, compliance scoring (ISO 27001, NIST CSF, ASD E8, PCI DSS, HIPAA, CIS) |
| **AI Self-Healing** | When tools fail or return zero results, the Pi's AI diagnoses and attempts a fix — then retries automatically |
| **AI Post-Pentest Review** | After each pentest, AI reviews all tool output and writes an `ai-review.txt` with improvement suggestions |
| **Premium Reports** | Branded HTML + PDF with executive summary, compliance graphs (risk gauge, cadence bars, severity charts), CVSS scoring, remediation matrix, root cause analysis |
| **Evidence Compilation** | All raw tool output compiled into `evidence.txt` for manual review — every command, every result |
| **Chain Scanning** | Re-scan discovered subdomains, hosts, and URLs from the results page — select targets and launch batch scans |
| **Job Queue** | Run up to 2 pentests in parallel. Additional jobs auto-queue and start when a slot frees |
| **Web Terminal** | ttyd — full bash terminal in your browser, proxied through nginx |
| **One-Click Launchers** | Click any tool → terminal opens with 44 beginner-friendly guides |
| **System Monitor** | Live CPU/RAM/Disk/Temp with colored progress bars |
| **RSS News Ticker** | Scrolling cybersecurity headlines from 9 sources |
| **Threat Intelligence** | Live CVE feed, AlienVault OTX pulses, attack map |
| **Podcast Player** | Built-in player for cybersecurity podcasts (Risky Business, Darknet Diaries, Smashing Security) |
| **Cockpit** | System management web UI on port 9090 |

## 🛠 Tools Included (50+)

| Category | Tools |
|----------|-------|
| **Vulnerability Scanning** | Nmap (50+ CVE scripts), Nikto, SQLmap, SearchSploit, Nuclei (8000+ templates), OWASP ZAP, Dalfox |
| **Network Scanning** | Nmap, Masscan, Netdiscover, Naabu, Amass, Subfinder, TheHarvester, Httpx |
| **Network Analysis** | tcpdump, tshark, Netcat, Socat |
| **Password Attacks** | Hashcat, John, Hydra, Crunch, CeWL |
| **Windows/AD** | Enum4linux, SMB Client, Impacket, Certipy, BloodHound, Coercer |
| **Web Application** | Gobuster, ffuf, Wfuzz, Dirb, WhatWeb, Wafw00f |
| **MITM & Tunneling** | Mitmproxy, Ettercap, Chisel, SSHuttle, Proxychains |
| **Forensics** | Autopsy (Web UI), Binwalk, Foremost, ExifTool, Steghide, dc3dd, Sleuthkit |
| **Wireless** | Aircrack-ng, Wifite, Reaver, PixieWPS, airbase-ng, Horst, hcxdumptool |
| **SSL/TLS** | testssl.sh, sslscan |

## 🤖 AI Chatbot — Model Failover

The chatbot supports **automatic model fallback** if the primary AI model is unavailable (API key expired, no credits, quota exceeded, etc.).

### How it works

1. The chatbot tries models in priority order (defined by the `OPENCODE_MODELS` environment variable)
2. If the **primary** model fails — especially with auth/credit errors — it automatically falls back to the **secondary** model
3. The response includes a `_model` field indicating which model answered

### Default model priority

| Priority | Model | Type |
|----------|-------|------|
| 1st | `opencode-go/deepseek-v4-pro` | Primary — Go subscription |
| 2nd | `opencode/deepseek-v4-flash-free` | Fallback — free tier |

### Configuration

Set `OPENCODE_MODELS` in the systemd service file as a comma-separated list (no spaces):

```ini
Environment=OPENCODE_MODELS=opencode-go/deepseek-v4-pro,opencode/deepseek-v4-flash-free
```

## 🏗 Architecture

```
dragonpi.local (port 80)
├── Custom Dashboard    → / (Flask :5000, nginx proxy)
├── DragonAI Chatbot   → /chat → Flask :5000 → OpenCode CLI (multi-model)
├── Pentest Console    → /pentest → Flask → 24+ tool pipeline (per-tool toggles)
├── Podcast Player     → /podcast → Flask → RSS feeds (client-side audio)
├── Web Terminal       → /terminal/ → nginx → ttyd :7681
├── Cockpit            → :9090
├── RSS Feed           → /rss → Flask proxy (9 sources)
├── Threat APIs        → /api/threat/* → CVE, OTX, live threats
└── Tool Launcher      → /term/TOOL → redirect → terminal
```

## 📁 File Structure

```
dragonpi/
├── install.sh                  # One-line installer
├── chatbot/
│   ├── app.py                  # Flask backend (dashboard, chat, podcast, pentest routes)
│   ├── pentest.py              # 24+ tool pentest engine + self-healing + AI review
│   └── templates/
│       ├── dashboard.html      # Custom dashboard UI
│       ├── index.html          # Chat UI
│       ├── podcast.html        # Podcast player
│       ├── pentest.html        # Pentest console UI
│       └── report_template.html # Premium HTML report template
├── dashboard/
│   └── config.yml              # Dashboard configuration (services, links, categories)
├── nginx/
│   └── dragonpi.conf           # Nginx reverse proxy config
├── services/
│   ├── chatbot.service         # DragonAI systemd unit (with model env vars)
│   ├── ttyd.service            # Web terminal systemd unit
│   └── autopsy.service         # Autopsy forensic UI systemd unit
├── scripts/
│   ├── dragonpi-shell          # Terminal wrapper (auto-runs tools from dashboard)
│   └── guides/                 # Beginner-friendly guide scripts for each tool
├── AGENTS.md                   # Project memory (gitignored — local only)
├── secrets.md                  # Credentials (gitignored — never committed)
└── .gitignore
```

## 🤖 AI Self-Healing & Post-Pentest Review

### Self-Healing
When tools fail or return zero results unexpectedly, the Pi's OpenCode AI:
1. **Diagnoses** the failure (missing package, wrong CLI flag, broken config)
2. **Fixes** with a safe, non-interactive bash command
3. **Retries** the tool automatically
4. **Logs** the diagnosis and result

Triggers: nmap 0 hosts, nikto 0 findings, nuclei 0 vulns, ZAP 0 alerts (both modes).

### Post-Pentest AI Review
After each pentest finishes:
1. All raw tool output is compiled into `evidence.txt`
2. The AI reviews it for anomalies, missed findings, tool configuration issues
3. An `ai-review.txt` is saved with improvement suggestions
4. Both files appear in the report downloads

### Per-Tool Toggles
Every tool in the pipeline has its own checkbox — enable/disable individual scanners.
External mode: 18 tools. Internal mode: 12 tools. All checked by default.

### Evidence File
`evidence.txt` contains every raw tool command output + the full pentest log.
Download it from the reports list or via `GET /api/pentest/log/<job_id>`.

## 🔧 Development

```bash
git clone https://github.com/RufflezAU/dragonpi.git
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
- OpenCode account (free tier works — subscription unlocks premium models)

## 🔐 Security Notes

- **No secrets in git**: password files, API keys, `.env` files, and `*secret*` patterns are all gitignored
- `secrets.md` and `AGENTS.md` are local-only by design (listed in `.gitignore`)
- The chatbot authenticates via the OpenCode CLI — no API keys stored in the codebase
- All dashboard config is served from `/opt/dragonpi/dashboard/config.yml`

## 📜 License

MIT — Use responsibly. Only test systems you own or have permission to test.
