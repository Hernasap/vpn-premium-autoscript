#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "Jalankan script ini sebagai root"
  exit 1
fi

read -p "Masukkan domain kamu: " domain
if [[ -z "$domain" ]]; then
  echo "Domain tidak boleh kosong!"
  exit 1
fi

mkdir -p /etc/myvpn
echo "$domain" > /etc/myvpn/domain
echo "Domain berhasil disimpan: $domain"

apt-get update -y
apt-get install nginx curl socat -y

cat > /etc/nginx/sites-available/default << END
server {
    listen 80;
    server_name $domain;

    location / {
        return 200 'VPN Premium Aktif di $domain';
        add_header Content-Type text/plain;
    }
}
END

systemctl restart nginx
echo "Instalasi selesai. VPN aktif di domain: $domain"
