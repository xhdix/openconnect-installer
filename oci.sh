#!/bin/bash
# pre-alpha version for openconnect installer in Debian
#
# bash oci.sh your-server-IP first-username certificate-name organization-name

###### Main

SERVER_IP=
USER_NAME="testuser"
SERVICE_NAME="service"
ORG_NAME="organization"

SERVER_IP=$1
USER_NAME=$2
SERVICE_NAME=$3
ORG_NAME=$4

if [[ $SERVER_IP == "" ]] ; then
  echo "run:\n bash oci.sh your-server-IP first-username certificate-name organization-name"
  exit
fi

lsof -i :443

apt update
apt dist-upgrade 
apt install build-essential pkg-config libgnutls28-dev libwrap0-dev libpam0g-dev libseccomp-dev libreadline-dev libnl-route-3-dev -y
apt install ocserv -y

apt install gnutls-bin -y

cd ~
mkdir certificates
cd certificates
cat > ca.tmpl << "EOF"
cn="SERVICE_NAME"
organization="ORG_NAME"
serial=1
expiration_days=3650
ca
signing_key
cert_signing_key
crl_signing_key
EOF

sed -i "s/\SERVICE_NAME/$SERVICE_NAME/" ./ca.tmpl
sed -i "s/\ORG_NAME/$ORG_NAME/" ./ca.tmpl

certtool --generate-privkey --outfile ca-key.pem
certtool --generate-self-signed --load-privkey ca-key.pem --template ca.tmpl --outfile ca-cert.pem
cat > server.tmpl << "EOF"
cn="SERVER_IP"
organization="ORG_NAME"
expiration_days=3650
signing_key
encryption_key
tls_www_server
EOF

sed -i "s/\SERVER_IP/$SERVER_IP/" ./server.tmpl
sed -i "s/\ORG_NAME/$ORG_NAME/" ./server.tmpl

certtool --generate-privkey --outfile server-key.pem
certtool --generate-certificate --load-privkey server-key.pem --load-ca-certificate ca-cert.pem --load-ca-privkey ca-key.pem --template server.tmpl --outfile server-cert.pem
cp server-cert.pem server-key.pem /etc/ocserv

sed -i 's/auth = "pam\[gid-min=1000]"/auth = "plain\[\/etc\/ocserv\/ocpasswd]"/g' /etc/ocserv/ocserv.conf
sed -i 's/try-mtu-discovery = false/try-mtu-discovery = true/' /etc/ocserv/ocserv.conf
sed -i 's/dns = 192.168.1.2/dns = 1.1.1.1\ndns = 8.8.8.8/' /etc/ocserv/ocserv.conf
sed -i 's/#tunnel-all-dns = true/tunnel-all-dns = true/' /etc/ocserv/ocserv.conf
sed -i 's/server-cert = \/etc\/ssl\/certs\/ssl-cert-snakeoil.pem/server-cert=\/etc\/ocserv\/server-cert.pem/' /etc/ocserv/ocserv.conf
sed -i 's/server-key = \/etc\/ssl\/private\/ssl-cert-snakeoil.key/server-key=\/etc\/ocserv\/server-key.pem/' /etc/ocserv/ocserv.conf
sed -i 's/ipv4-network = 192.168.1.0/ipv4-network = 192.168.129.0/' /etc/ocserv/ocserv.conf
sed -i 's/#mtu = 1420/mtu = 1420/' /etc/ocserv/ocserv.conf
sed -i 's/route = 10.10.10.0\/255.255.255.0/#route = 10.10.10.0\/255.255.255.0/' /etc/ocserv/ocserv.conf
sed -i 's/route = 192.168.0.0\/255.255.0.0/#route = 192.168.0.0\/255.255.0.0/' /etc/ocserv/ocserv.conf
sed -i 's/route = fef4:db8:1000:1001::\/64/#route = fef4:db8:1000:1001::\/64/' /etc/ocserv/ocserv.conf
sed -i 's/no-route = 192.168.5.0\/255.255.255.0/#no-route = 192.168.5.0\/255.255.255.0/' /etc/ocserv/ocserv.conf

iptables -I INPUT -p tcp --dport 443 -j ACCEPT
iptables -I INPUT -p udp --dport 443 -j ACCEPT
iptables -t nat -A POSTROUTING -j MASQUERADE
iptables -A FORWARD -s 192.168.128.0/21 -j ACCEPT

sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf

sysctl -p /etc/sysctl.conf

ocpasswd -c /etc/ocserv/ocpasswd $USER_NAME
#ipnut password
#input password

systemctl enable ocserv.service

systemctl mask ocserv.socket

cp /lib/systemd/system/ocserv.service /etc/systemd/system/ocserv.service

sed -i 's/Requires=ocserv.socket/#Requires=ocserv.socket/' /etc/systemd/system/ocserv.service
sed -i 's/Also=ocserv.socket/#Also=ocserv.socket/' /etc/systemd/system/ocserv.service

systemctl daemon-reload
systemctl stop ocserv.socket > /dev/null
systemctl disable ocserv.socket > /dev/null
systemctl restart ocserv.service > /dev/null
systemctl status ocserv.service > /dev/null

apt install iptables-persistent
#input ok 
#input ok

iptables-save > /etc/iptables.rules

systemctl status ocserv.service
