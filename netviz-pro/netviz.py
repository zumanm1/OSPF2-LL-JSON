#!/usr/bin/env python3
"""
NetViz Pro - Unified CLI Manager
================================
Usage: python3 netviz.py [command] [options]

Commands:
  check     - Verify system requirements
  install   - Run installation (with optional flags)
  start     - Start all services
  stop      - Stop all services
  restart   - Restart all services
  status    - Show service status
  logs      - View logs (--frontend, --backend, --all)
  reset     - Reset databases (--db, --auth, --all)
  help      - Show this help

Examples:
  python3 netviz.py check
  python3 netviz.py start
  python3 netviz.py status
  python3 netviz.py logs --backend
  python3 netviz.py reset --auth
"""

import os
import sys
import subprocess
import signal
import time
import argparse
from pathlib import Path

# Configuration
SCRIPT_DIR = Path(__file__).parent.resolve()
LOG_FILE = Path("/tmp/netviz-pro.log")
PORTS = {"frontend": 9040, "backend": 9041}
DB_FILES = {
    "users": SCRIPT_DIR / "server" / "netviz.db",
    "main": SCRIPT_DIR / "server" / "users.db"
}

# Colors for terminal output
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    CYAN = '\033[0;36m'
    NC = '\033[0m'  # No Color
    BOLD = '\033[1m'

def print_header(text: str):
    """Print a styled header"""
    print()
    print(f"{Colors.BLUE}{'=' * 60}{Colors.NC}")
    print(f"{Colors.BLUE}  {text}{Colors.NC}")
    print(f"{Colors.BLUE}{'=' * 60}{Colors.NC}")
    print()

def print_success(text: str):
    print(f"  {Colors.GREEN}✓{Colors.NC} {text}")

def print_error(text: str):
    print(f"  {Colors.RED}✗{Colors.NC} {text}")

def print_warn(text: str):
    print(f"  {Colors.YELLOW}!{Colors.NC} {text}")

def print_info(text: str):
    print(f"  {Colors.CYAN}→{Colors.NC} {text}")

def get_pid_on_port(port: int) -> int | None:
    """Get the PID of process listening on a port"""
    try:
        result = subprocess.run(
            ["lsof", "-ti", f":{port}"],
            capture_output=True, text=True
        )
        if result.returncode == 0 and result.stdout.strip():
            return int(result.stdout.strip().split('\n')[0])
    except Exception:
        pass
    return None

def is_service_running(port: int) -> tuple[bool, int | None]:
    """Check if service is running on port, return (running, pid)"""
    pid = get_pid_on_port(port)
    return (pid is not None, pid)

def run_script(script_name: str, capture_output: bool = False) -> subprocess.CompletedProcess:
    """Run a shell script from the app directory"""
    script_path = SCRIPT_DIR / script_name
    if not script_path.exists():
        print_error(f"Script not found: {script_name}")
        sys.exit(1)

    return subprocess.run(
        ["bash", str(script_path)],
        cwd=SCRIPT_DIR,
        capture_output=capture_output,
        text=True
    )

# ============================================================================
# COMMANDS
# ============================================================================

def cmd_check():
    """Verify system requirements"""
    print_header("NetViz Pro - System Check")
    run_script("check.sh")

def cmd_start():
    """Start all services"""
    print_header("NetViz Pro - Starting Services")
    run_script("start.sh")

def cmd_stop():
    """Stop all services"""
    print_header("NetViz Pro - Stopping Services")
    run_script("stop.sh")

def cmd_restart():
    """Restart all services"""
    print_header("NetViz Pro - Restarting Services")
    run_script("restart.sh")

def cmd_status():
    """Show service status"""
    print_header("NetViz Pro - Service Status")

    all_running = True

    for name, port in PORTS.items():
        running, pid = is_service_running(port)
        if running:
            print_success(f"{name.capitalize():12} (port {port}): RUNNING (PID: {pid})")
        else:
            print_error(f"{name.capitalize():12} (port {port}): NOT RUNNING")
            all_running = False

    print()

    # Database status
    print(f"  {Colors.CYAN}Databases:{Colors.NC}")
    for name, path in DB_FILES.items():
        if path.exists():
            size = path.stat().st_size
            print_success(f"{name}: {path.name} ({size} bytes)")
        else:
            print_warn(f"{name}: Not found (will be created on first run)")

    print()

    # Log file status
    if LOG_FILE.exists():
        size = LOG_FILE.stat().st_size
        print_info(f"Log file: {LOG_FILE} ({size} bytes)")
    else:
        print_info(f"Log file: {LOG_FILE} (not yet created)")

    print()

    if all_running:
        print(f"  {Colors.GREEN}All services are running!{Colors.NC}")
        print()
        print(f"  Access: {Colors.CYAN}http://localhost:9040{Colors.NC}")
    else:
        print(f"  {Colors.YELLOW}Some services are not running.{Colors.NC}")
        print(f"  Run: {Colors.CYAN}python3 netviz.py start{Colors.NC}")

    print()

def cmd_logs(args):
    """View logs"""
    print_header("NetViz Pro - Logs")

    if not LOG_FILE.exists():
        print_warn(f"Log file not found: {LOG_FILE}")
        print_info("Start the application first: python3 netviz.py start")
        return

    lines = args.lines if hasattr(args, 'lines') and args.lines else 50
    follow = args.follow if hasattr(args, 'follow') else False

    if follow:
        print_info(f"Following log file (Ctrl+C to stop)...")
        print()
        try:
            subprocess.run(["tail", "-f", str(LOG_FILE)])
        except KeyboardInterrupt:
            print()
            print_info("Stopped following logs.")
    else:
        print_info(f"Last {lines} lines from {LOG_FILE}:")
        print()
        subprocess.run(["tail", f"-{lines}", str(LOG_FILE)])

    print()

def cmd_reset(args):
    """Reset databases"""
    print_header("NetViz Pro - Reset")

    reset_db = args.db if hasattr(args, 'db') else False
    reset_auth = args.auth if hasattr(args, 'auth') else False
    reset_all = args.all if hasattr(args, 'all') else False

    if not (reset_db or reset_auth or reset_all):
        print_warn("No reset option specified.")
        print()
        print("  Usage:")
        print(f"    {Colors.CYAN}python3 netviz.py reset --db{Colors.NC}    Reset main database")
        print(f"    {Colors.CYAN}python3 netviz.py reset --auth{Colors.NC}  Reset auth (login counts)")
        print(f"    {Colors.CYAN}python3 netviz.py reset --all{Colors.NC}   Full factory reset")
        print()
        return

    if reset_all:
        reset_db = True
        reset_auth = True

    # Confirm
    print(f"  {Colors.YELLOW}WARNING: This will delete data!{Colors.NC}")
    if reset_db:
        print_warn("Will reset: Main database (users.db)")
    if reset_auth:
        print_warn("Will reset: Authentication state")
    print()

    confirm = input("  Continue? (y/N): ").strip().lower()
    if confirm != 'y':
        print_info("Cancelled.")
        return

    print()

    # Stop services first
    print_info("Stopping services...")
    for port in PORTS.values():
        pid = get_pid_on_port(port)
        if pid:
            try:
                os.kill(pid, signal.SIGTERM)
                time.sleep(0.5)
                os.kill(pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
    print_success("Services stopped")

    # Reset database
    if reset_db:
        for name, path in DB_FILES.items():
            if path.exists():
                path.unlink()
                print_success(f"Deleted: {path.name}")
            else:
                print_info(f"Already absent: {path.name}")

    # Reset auth (for now, same as db since auth is in the db)
    if reset_auth and not reset_db:
        # Auth state is stored in the database, so we need to handle differently
        # For now, we'll just remove the database
        for name, path in DB_FILES.items():
            if "user" in name.lower() and path.exists():
                path.unlink()
                print_success(f"Deleted: {path.name}")

    print()
    print_success("Reset complete!")
    print()
    print(f"  {Colors.CYAN}Database will be recreated on next start with:{Colors.NC}")
    print()
    print("  ┌─────────────────────────────────────────┐")
    print("  │  Username: admin                        │")
    print("  │  Password: admin123                     │")
    print("  └─────────────────────────────────────────┘")
    print()

    # Ask to restart
    restart = input("  Start services now? (Y/n): ").strip().lower()
    if restart != 'n':
        cmd_start()

def cmd_install(args):
    """Run installation"""
    print_header("NetViz Pro - Install")

    with_deps = args.with_deps if hasattr(args, 'with_deps') else False
    clean = args.clean if hasattr(args, 'clean') else False
    force = args.force if hasattr(args, 'force') else False

    # Build the command
    if clean or force:
        # Use install.sh for clean installation
        print_info("Running clean installation...")
        run_script("install.sh")
    elif with_deps:
        # Check and install dependencies first
        print_info("Checking and installing dependencies...")
        print_warn("Note: --with-deps requires manual installation of Node.js if missing")
        run_script("prep.sh")
    else:
        # Standard install
        run_script("prep.sh")

def cmd_help():
    """Show help"""
    print(__doc__)

# ============================================================================
# MAIN
# ============================================================================

def main():
    parser = argparse.ArgumentParser(
        description="NetViz Pro - Unified CLI Manager",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python3 netviz.py check           Check system requirements
  python3 netviz.py start           Start all services
  python3 netviz.py stop            Stop all services
  python3 netviz.py status          Show service status
  python3 netviz.py logs            View last 50 log lines
  python3 netviz.py logs -f         Follow logs in real-time
  python3 netviz.py reset --auth    Reset authentication
  python3 netviz.py reset --all     Full factory reset
        """
    )

    subparsers = parser.add_subparsers(dest="command", help="Available commands")

    # check
    subparsers.add_parser("check", help="Verify system requirements")

    # install
    install_parser = subparsers.add_parser("install", help="Run installation")
    install_parser.add_argument("--with-deps", action="store_true", help="Install Node.js/npm if missing")
    install_parser.add_parser if False else None  # Placeholder
    install_parser.add_argument("--clean", action="store_true", help="Clean installation (remove old first)")
    install_parser.add_argument("--force", action="store_true", help="Force reinstall")

    # start
    subparsers.add_parser("start", help="Start all services")

    # stop
    subparsers.add_parser("stop", help="Stop all services")

    # restart
    subparsers.add_parser("restart", help="Restart all services")

    # status
    subparsers.add_parser("status", help="Show service status")

    # logs
    logs_parser = subparsers.add_parser("logs", help="View logs")
    logs_parser.add_argument("-f", "--follow", action="store_true", help="Follow logs in real-time")
    logs_parser.add_argument("-n", "--lines", type=int, default=50, help="Number of lines to show")

    # reset
    reset_parser = subparsers.add_parser("reset", help="Reset databases")
    reset_parser.add_argument("--db", action="store_true", help="Reset main database")
    reset_parser.add_argument("--auth", action="store_true", help="Reset authentication state")
    reset_parser.add_argument("--all", action="store_true", help="Full factory reset")

    # help
    subparsers.add_parser("help", help="Show help")

    args = parser.parse_args()

    if args.command is None or args.command == "help":
        cmd_help()
    elif args.command == "check":
        cmd_check()
    elif args.command == "install":
        cmd_install(args)
    elif args.command == "start":
        cmd_start()
    elif args.command == "stop":
        cmd_stop()
    elif args.command == "restart":
        cmd_restart()
    elif args.command == "status":
        cmd_status()
    elif args.command == "logs":
        cmd_logs(args)
    elif args.command == "reset":
        cmd_reset(args)
    else:
        print_error(f"Unknown command: {args.command}")
        cmd_help()
        sys.exit(1)

if __name__ == "__main__":
    main()
