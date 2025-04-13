#!/bin/bash

# VPN Premium Auto Installer
# Recode & Maintained by https://github.com/Hernasap

# Cek akses root
if [ "$EUID" -ne 0 ]; then
  echo "Silakan jalankan script ini sebagai root"
  exit 1
fi

# Nonaktifkan IPv6
echo "[VPN Premium] Menonaktifkan IPv6..."
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1

# Update sistem dan install dependensi
echo "[VPN Premium] Update system & install tools..."
apt-get update -y
apt-get update --fix-missing
apt-get install -y wget curl screen dnsutils

# Download script utama
SCRIPT_URL="http://autoscript.yha.my.id/?key=mk1gukll62o2WS2QELx2kE"
SCRIPT_NAME="vpnpremium-installer.sh"

echo "[VPN Premium] Mengunduh script utama..."
curl -L -k -sS "$SCRIPT_URL" -o "$SCRIPT_NAME"

# Jalankan di screen
if [ -f "$SCRIPT_NAME" ]; then
  chmod +x "$SCRIPT_NAME"
  screen -S VPNPremiumInstall ./"$SCRIPT_NAME"
else
  echo "[ERROR] Gagal mengunduh script!"
  exit 1
fi
