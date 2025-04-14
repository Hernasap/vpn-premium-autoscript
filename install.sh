#!/bin/bash
# === Installasi VPN Premium Auto Script ===
# === BY XXDonn ===

# Set domain
read -p "Masukkan domain: " DOMAIN
echo $DOMAIN > /etc/vpn-premium/domain

# Update dan install dependensi
echo "Update dan install dependensi..."
apt-get update -y && apt-get upgrade -y
apt-get install -y wget curl screen jq dnsutils

# Install Xray
echo "Install Xray..."
bash <(curl -L https://github.com/XTLS/Xray-core/releases/download/v1.7.5/xray-linux-64.zip) -o /etc/xray/xray

# Set SSL
echo "Set SSL..."
mkdir -p /etc/xray
curl https://get.acme.sh | sh
~/.acme.sh/acme.sh --issue -d $DOMAIN --standalone

# Setup Xray config
cat > /etc/xray/config.json <<EOF
{
    "inbounds": [
        {
            "port": 443,
            "listen": "0.0.0.0",
            "protocol": "vmess",
            "settings": {
                "clients": []
            },
            "streamSettings": {
                "network": "ws",
                "security": "tls",
                "tlsSettings": {
                    "certificates": [
                        {
                            "certificateFile": "/etc/xray/xray.crt",
                            "keyFile": "/etc/xray/xray.key"
                        }
                    ]
                },
                "wsSettings": {
                    "path": "/vmess"
                }
            }
        }
    ]
}
EOF

# Restart Xray
systemctl restart xray

# Menu
cat > /etc/vpn-premium/menu.sh <<EOF
#!/bin/bash
echo "=== VPN Premium Menu ==="
echo "1. Tambah Akun VMess"
echo "2. Tambah Akun VLESS"
echo "3. Tambah Akun Trojan WS"
echo "4. Tambah Akun Trojan gRPC"
echo "5. Hapus Akun"
echo "6. Perpanjang Akun"
echo "7. Exit"
read -p "Pilih menu: " choice

case $choice in
    1)
        bash /etc/vpn-premium/add-vmess.sh
        ;;
    2)
        bash /etc/vpn-premium/add-vless.sh
        ;;
    3)
        bash /etc/vpn-premium/add-trojan.sh
        ;;
    4)
        bash /etc/vpn-premium/add-trojan-grpc.sh
        ;;
    5)
        bash /etc/vpn-premium/delete.sh
        ;;
    6)
        bash /etc/vpn-premium/extend.sh
        ;;
    7)
        exit
        ;;
    *)
        echo "Pilihan tidak valid"
        ;;
esac
EOF

# Admin tools
cat > /etc/vpn-premium/admin.sh <<EOF
#!/bin/bash
echo "=== Admin Menu ==="
echo "1. Tambah Akun"
echo "2. Hapus Akun"
echo "3. Perpanjang Akun"
echo "4. Kembali"
read -p "Pilih menu admin: " choice

case $choice in
    1)
        bash /etc/vpn-premium/menu.sh
        ;;
    2)
        bash /etc/vpn-premium/delete.sh
        ;;
    3)
        bash /etc/vpn-premium/extend.sh
        ;;
    4)
        exit
        ;;
    *)
        echo "Pilihan tidak valid"
        ;;
esac
EOF

chmod +x /etc/vpn-premium/menu.sh
chmod +x /etc/vpn-premium/admin.sh

# File add-akun VMess
cat > /etc/vpn-premium/add-vmess.sh <<EOF
#!/bin/bash
# === Tambah Akun VMess ===
read -p "Masukkan username: " USER
read -p "Masa aktif (hari): " MASA_AKTIF
read -p "Maksimal jumlah IP yang diperbolehkan: " MAX_IP
UUID=$(cat /proc/sys/kernel/random/uuid)
EXP=$(date -d "+$MASA_AKTIF days" +"%Y-%m-%d")
DOMAIN=$(cat /etc/vpn-premium/domain)
EMAIL="$USER@vpn-premium"

# Buat config client
cat > /etc/xray/client/\${USER}_vmess.json <<EOF
{
    "v": "2",
    "ps": "\$USER",
    "add": "\$DOMAIN",
    "port": "443",
    "id": "\$UUID",
    "aid": "0",
    "net": "ws",
    "path": "/vmess",
    "type": "none",
    "host": "\$DOMAIN",
    "tls": "tls"
}
EOF

# Tambahkan ke config.json
jq '.inbounds += [{
    "port": 443,
    "protocol": "vmess",
    "settings": {
        "clients": [{
            "id": "\$UUID",
            "alterId": 0,
            "email": "\$EMAIL"
        }]
    },
    "streamSettings": {
        "network": "ws",
        "security": "tls",
        "tlsSettings": {"certificates": [{"certificateFile": "/etc/xray/xray.crt", "keyFile": "/etc/xray/xray.key"}]},
        "wsSettings": {"path": "/vmess"}
    },
    "sniffing": {"enabled": true, "destOverride": ["http", "tls"]},
    "tag": "\$USER"
}]' /etc/xray/config.json > tmp && mv tmp /etc/xray/config.json

# Simpan limit IP ke file tracking
mkdir -p /etc/vpn-premium/user-limit
echo "\$MAX_IP" > /etc/vpn-premium/user-limit/\$USER

# Restart xray
systemctl restart xray

# Output link
ENCODED=$(base64 -w 0 /etc/xray/client/\${USER}_vmess.json)
LINK="vmess://\$ENCODED"
echo -e "\n=== VMess Config untuk \$USER ==="
echo "\$LINK"
echo "Masa aktif sampai: \$EXP"
echo "Limit IP aktif: \$MAX_IP"
echo "==============================="
EOF

chmod +x /etc/vpn-premium/add-vmess.sh

# File add-akun VLESS
cat > /etc/vpn-premium/add-vless.sh <<EOF
#!/bin/bash
# === Tambah Akun VLESS ===
read -p "Masukkan username: " USER
read -p "Masa aktif (hari): " MASA_AKTIF
read -p "Maksimal jumlah IP yang diperbolehkan: " MAX_IP
UUID=$(cat /proc/sys/kernel/random/uuid)
EXP=$(date -d "+$MASA_AKTIF days" +"%Y-%m-%d")
DOMAIN=$(cat /etc/vpn-premium/domain)
EMAIL="$USER@vpn-premium"

# Buat config client
cat > /etc/xray/client/\${USER}_vless.json <<EOF
{
    "v": "2",
    "ps": "\$USER",
    "add": "\$DOMAIN",
    "port": "443",
    "id": "\$UUID",
    "aid": "0",
    "net": "ws",
    "type": "none",
    "host": "\$DOMAIN",
    "path": "/vless",
    "tls": "tls"
}
EOF

# Tambahkan ke config.json
jq '.inbounds += [{
    "port": 443,
    "protocol": "vless",
    "settings": {
        "clients": [{
            "id": "\$UUID",
            "email": "\$EMAIL",
            "flow": "xtls-rprx-vision"
        }],
        "decryption": "none"
    },
    "streamSettings": {
        "network": "ws",
        "security": "tls",
        "tlsSettings": {"certificates": [{"certificateFile": "/etc/xray/xray.crt", "keyFile": "/etc/xray/xray.key"}]},
        "wsSettings": {"path": "/vless"}
    },
    "tag": "\$USER"
}]' /etc/xray/config.json > tmp && mv tmp /etc/xray/config.json

# Simpan limit IP ke file tracking
mkdir -p /etc/vpn-premium/user-limit
echo "\$MAX_IP" > /etc/vpn-premium/user-limit/\$USER

# Restart xray
systemctl restart xray

# Output link
LINK="vless://\$UUID@\${DOMAIN}:443?encryption=none&security=tls&type=ws&host=\$DOMAIN&path=%2Fvless#\$USER"
echo -e "\n=== VLESS Config untuk \$USER ==="
echo "\$LINK"
echo "Masa aktif sampai: \$EXP"
echo "Limit IP aktif: \$MAX_IP"
echo "==============================="
EOF

chmod +x /etc/vpn-premium/add-vless.sh
