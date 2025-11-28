# NetViz Pro - Installation Guide

**Version: 3.0**
**For Ubuntu 24.04 LTS**
**Repository: https://github.com/zumanm1/OSPF2-LL-JSON**

---

## Table of Contents

1. [Overview](#1-overview)
2. [System Requirements](#2-system-requirements)
3. [Quick Start (Automated)](#3-quick-start-automated)
4. [Manual Installation](#4-manual-installation)
5. [Management Commands](#5-management-commands)
6. [Troubleshooting](#6-troubleshooting)
7. [Verified Test Results](#7-verified-test-results)

---

## 1. Overview

NetViz Pro is a React-based OSPF network topology visualizer with:
- Interactive network graph visualization using D3.js
- Dijkstra-based path analysis between nodes
- 14 analysis modals (Pair, Impact, Transit, What-If, Matrix, etc.)
- Theme support (dark/light mode)
- LocalStorage persistence
- JWT-based authentication

### Architecture

| Component | Technology | Port |
|-----------|------------|------|
| Frontend | React 19 + TypeScript + Vite | 9040 |
| Backend | Express.js + SQLite | 9041 |
| Visualization | D3.js | - |
| Database | better-sqlite3 | - |

---

## 2. System Requirements

### Minimum Hardware

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| CPU | 2 cores | 4 cores |
| RAM | 2 GB | 4 GB |
| Disk | 5 GB free | 10 GB free |

### Software Requirements

- **Node.js**: v18.x or higher (v20.x recommended)
- **npm**: v8.x or higher (v10.x recommended)
- **Git**: v2.x or higher
- **curl**: For health checks (optional)

### Supported Operating Systems

- Ubuntu 24.04 LTS (tested)
- Ubuntu 22.04 LTS (compatible)
- macOS (compatible)
- Other Linux distributions (should work)

---

## 3. Quick Start (Automated)

### Option A: Standard Installation (Prerequisites already installed)

```bash
# Clone the repository
git clone https://github.com/zumanm1/OSPF2-LL-JSON.git
cd OSPF2-LL-JSON/netviz-pro

# Make scripts executable
chmod +x *.sh *.py

# Run installation
./install.sh

# Access at http://localhost:9040
# Username: admin
# Password: admin123
```

### Option B: Install with Dependencies

If Node.js or npm are missing, the installer can install them:

```bash
git clone https://github.com/zumanm1/OSPF2-LL-JSON.git
cd OSPF2-LL-JSON/netviz-pro
chmod +x *.sh *.py
./install.sh --with-deps
```

### Option C: Clean Installation (7-Phase)

Full clean install that removes old installations first:

```bash
./install.sh --clean
```

### Option D: Force Reinstall

Force reinstall even if already installed:

```bash
./install.sh --force
```

### Installation Options Summary

| Option | Description |
|--------|-------------|
| `./install.sh` | Standard install (validates prerequisites) |
| `./install.sh --with-deps` | Install Node.js, npm, Python if missing |
| `./install.sh --clean` | 7-phase clean install (remove old, install fresh) |
| `./install.sh --force` | Force reinstall even if exists |
| `./install.sh --help` | Show help |

### 7-Phase Installation Process

When using `--clean`, the installer performs:

| Phase | Description |
|-------|-------------|
| Phase 1 | Remove old Node.js |
| Phase 2 | Remove old npm cache |
| Phase 3 | Clean Python environment |
| Phase 4 | Install/verify Python 3.12 |
| Phase 5 | Install/verify Node.js 20.x |
| Phase 6 | Install application dependencies |
| Phase 7 | Validate and start application |

---

## 4. Manual Installation

### Step 4.1: Install System Dependencies (Ubuntu 24.04)

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js 20.x (official NodeSource repo)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install additional tools
sudo apt-get install -y git curl

# Verify installations
node --version    # Should show v20.x
npm --version     # Should show 10.x
git --version     # Should show 2.x
```

### Step 4.2: Clone Repository

```bash
cd ~
git clone https://github.com/zumanm1/OSPF2-LL-JSON.git
cd OSPF2-LL-JSON/netviz-pro
chmod +x *.sh *.py
```

### Step 4.3: Install npm Dependencies

```bash
npm install
```

### Step 4.4: Start the Application

```bash
./start.sh
```

### Step 4.5: Access the Application

| Component | URL |
|-----------|-----|
| Frontend | http://localhost:9040 |
| Auth API | http://localhost:9041/api |

Default credentials:
- **Username**: admin
- **Password**: admin123

---

## 5. Management Commands

### Shell Scripts

| Command | Description |
|---------|-------------|
| `./start.sh` | Start all services |
| `./stop.sh` | Stop all services |
| `./restart.sh` | Restart all services |
| `./status.sh` | Show service status |
| `./logs.sh` | View logs (last 50 lines) |
| `./logs.sh -f` | Follow logs in real-time |
| `./logs.sh --errors` | Show only errors |
| `./reset.sh --auth` | Reset authentication |
| `./reset.sh --db` | Reset database |
| `./reset.sh --all` | Full factory reset |
| `./check.sh` | Verify prerequisites |

### Python CLI Manager (netviz.py)

```bash
# Check system requirements
python3 netviz.py check

# Service management
python3 netviz.py start
python3 netviz.py stop
python3 netviz.py restart
python3 netviz.py status

# View logs
python3 netviz.py logs
python3 netviz.py logs -f        # Follow logs
python3 netviz.py logs -n 100    # Last 100 lines

# Reset options
python3 netviz.py reset --db     # Reset database
python3 netviz.py reset --auth   # Reset authentication
python3 netviz.py reset --all    # Full reset
```

---

## 6. Troubleshooting

### Node.js Not Found

```bash
# Install Node.js 20.x
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Or run install with deps
./install.sh --with-deps
```

### npm Install Fails

```bash
# Clear cache and retry
npm cache clean --force
rm -rf node_modules package-lock.json
npm install
```

### Port Already in Use

```bash
# Check what's using ports
lsof -i:9040
lsof -i:9041

# Kill processes
./stop.sh

# Or manually
lsof -ti:9040,9041 | xargs kill -9
```

### Service Won't Start

```bash
# Check logs
./logs.sh --errors

# Or view full log
tail -100 /tmp/netviz-pro.log
```

### Password Reset

```bash
# Reset to default admin/admin123
./reset.sh --auth
./start.sh
```

### Full Factory Reset

```bash
./reset.sh --all -y
./start.sh
```

---

## 7. Verified Test Results

### Test Environment

| Server | IP | OS | Status |
|--------|----|----|--------|
| VM 172 | 172.16.39.172 | Ubuntu 24.04.2 LTS | ✅ Verified |
| VM 173 | 172.16.39.173 | Ubuntu 24.04.3 LTS | ✅ Verified |

### Test Results Summary

#### VM 172.16.39.172

| Test | Command | Result |
|------|---------|--------|
| Standard Install | `./install.sh` | ✅ PASS |
| Stop Services | `./stop.sh` | ✅ PASS |
| Start Services | `./start.sh` | ✅ PASS |
| Force Install | `./install.sh --force` | ✅ PASS |

#### VM 172.16.39.173

| Test | Command | Result |
|------|---------|--------|
| Standard Install | `./install.sh` | ✅ PASS |
| Stop Services | `./stop.sh` | ✅ PASS |
| Start Services | `./start.sh` | ✅ PASS |

### Validated Versions

| Component | Version |
|-----------|---------|
| Node.js | v20.19.6 |
| npm | 10.8.2 |
| Python | 3.12.3 |
| Git | 2.43.0 |

### Installation Time

| Phase | Duration |
|-------|----------|
| Clone repository | ~5 seconds |
| npm install | ~8 seconds |
| Start services | ~1 second |
| **Total** | **~15 seconds** |

---

## Quick Reference

| Action | Command |
|--------|---------|
| Fresh install | `./install.sh` |
| Install with deps | `./install.sh --with-deps` |
| Clean install | `./install.sh --clean` |
| Start | `./start.sh` |
| Stop | `./stop.sh` |
| Restart | `./restart.sh` |
| Status | `./status.sh` |
| View logs | `./logs.sh -f` |
| Reset auth | `./reset.sh --auth` |
| Full reset | `./reset.sh --all` |
| Check system | `./check.sh` |

---

## Support

- **Repository**: https://github.com/zumanm1/OSPF2-LL-JSON
- **Issues**: https://github.com/zumanm1/OSPF2-LL-JSON/issues

---

*Built with Claude Code - Version 3.0*
*Verified: November 28, 2025*
