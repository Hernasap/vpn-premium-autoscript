#!/bin/bash

# VPN Premium Auto Installer
# By https://github.com/Hernasap

# Cek akses root
if [ "$EUID" -ne 0 ]; then
  echo "Silakan jalankan sebagai root"
  exit 1
fi

# Nonaktifkan IPv6
echo "[VPN Premium] Menonaktifkan IPv6..."
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1

# Update sistem dan install alat bantu
echo "[VPN Premium] Update dan install tools..."
apt-get update -y
apt-get update --fix-missing
apt-get install -y wget curl screen dnsutils

# Unduh script utama dari repo Anda
SCRIPT_URL="https://raw.githubusercontent.com/Hernasap/vpn-premium-autoscript/main/vpn-premium.sh"
SCRIPT_FILE="vpn-premium.sh"

echo "[VPN Premium] Mengunduh script utama dari GitHub..."
curl -sS "$SCRIPT_URL" -o "$SCRIPT_FILE"

# Jalankan script utama
if [ -f "$SCRIPT_FILE" ]; then
  chmod +x "$SCRIPT_FILE"
  screen -S VPNPremiumInstall ./"$SCRIPT_FILE"
else
  echo "[ERROR] Script tidak ditemukan!"
  exit 1
fi
