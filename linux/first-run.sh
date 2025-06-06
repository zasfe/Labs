#!/usr/bin/env bash

tee ~/.bashrc<<EOF
PS1="\[\e[34m\\]\u@\h\[\e[0m\\]:\[\e[33m\\]\w\[\e[0m\\]\$ "
EOF

mkdir update-cloudflare-dns; cd update-cloudflare-dns
wget https://raw.githubusercontent.com/zasfe/Labs/refs/heads/master/Cloudflare/v4/update-cloudflare-dns.sh
wget https://raw.githubusercontent.com/zasfe/Labs/refs/heads/master/Cloudflare/v4/update-cloudflare-dns.conf
chmod 700 update-cloudflare-dns.sh

sudo tee /etc/ssh/sshd_config.d/70-port-38317-add.conf<<EOF
Port 22
EOF

sudo tee /etc/ssh/sshd_config.d/70-usedns-no.conf<<EOF
UseDNS no
EOF

sudo systemctl restart sshd


