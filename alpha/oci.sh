#!/bin/bash
# pre-alpha version for openconnect installer in Debian
#
# bash oci.sh first-username certificate-name organization-name

###### Main

SERVER_IP=`ip addr show | awk '/inet/ {print $2}' | grep -v "127.0.0.1" | grep -v "::" | cut -f1 -d"/"` &
wait
USER_NAME="testuser"
SERVICE_NAME="service"
ORG_NAME="organization"

#SERVER_IP=$1
USER_NAME=$1
SERVICE_NAME=$2
ORG_NAME=$3

if [[ $SERVER_IP == "" ]] ; then
  echo "run:\n bash oci.sh your-server-IP first-username certificate-name organization-name"
  exit
fi

#lsof -i :443

apt update > /dev/null &
wait
apt dist-upgrade -y &
wait
apt install build-essential pkg-config libgnutls28-dev libwrap0-dev libpam0g-dev libseccomp-dev libreadline-dev libnl-route-3-dev -y > /dev/null &
wait
apt install ocserv -y > /dev/null &
wait

apt install gnutls-bin -y > /dev/null &
wait

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

certtool --generate-privkey --outfile ca-key.pem &
wait
certtool --generate-self-signed --load-privkey ca-key.pem --template ca.tmpl --outfile ca-cert.pem &
wait
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

certtool --generate-privkey --outfile server-key.pem &
wait
certtool --generate-certificate --load-privkey server-key.pem --load-ca-certificate ca-cert.pem --load-ca-privkey ca-key.pem --template server.tmpl --outfile server-cert.pem &
wait
cp server-cert.pem server-key.pem /etc/ocserv

sed -i 's/auth = "pam\[gid-min=1000]"/auth = "plain\[\/etc\/ocserv\/ocpasswd]"/g' /etc/ocserv/ocserv.conf
sed -i 's/try-mtu-discovery = false/try-mtu-discovery = true/' /etc/ocserv/ocserv.conf
sed -i 's/dns = 192.168.1.2/dns = 1.1.1.1\ndns = 8.8.8.8/' /etc/ocserv/ocserv.conf
sed -i 's/#tunnel-all-dns = true/tunnel-all-dns = true/' /etc/ocserv/ocserv.conf
sed -i 's/server-cert = \/etc\/ssl\/certs\/ssl-cert-snakeoil.pem/server-cert=\/etc\/ocserv\/server-cert.pem/' /etc/ocserv/ocserv.conf
sed -i 's/server-key = \/etc\/ssl\/private\/ssl-cert-snakeoil.key/server-key=\/etc\/ocserv\/server-key.pem/' /etc/ocserv/ocserv.conf
sed -i 's/ipv4-network = 192.168.1.0/ipv4-network = 192.168.128.0/' /etc/ocserv/ocserv.conf
sed -i 's/#mtu = 1420/mtu = 1420/' /etc/ocserv/ocserv.conf
#sed -i 's/#route = default/route = default/' /etc/ocserv/ocserv.conf # for use server like gateway
sed -i 's/route = 10.10.10.0\/255.255.255.0/#route = 10.10.10.0\/255.255.255.0/' /etc/ocserv/ocserv.conf
sed -i 's/route = 192.168.0.0\/255.255.0.0/#route = 192.168.0.0\/255.255.0.0/' /etc/ocserv/ocserv.conf
sed -i 's/route = fef4:db8:1000:1001::\/64/#route = fef4:db8:1000:1001::\/64/' /etc/ocserv/ocserv.conf
sed -i 's/no-route = 192.168.5.0\/255.255.255.0/#no-route = 192.168.5.0\/255.255.255.0/' /etc/ocserv/ocserv.conf

iptables -I INPUT -p tcp --dport 443 -j ACCEPT
iptables -I INPUT -p udp --dport 443 -j ACCEPT
iptables -t nat -A POSTROUTING -j MASQUERADE
iptables -I FORWARD -d 192.168.128.0/21 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -s 192.168.128.0/21 -j ACCEPT

sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf

sysctl -p /etc/sysctl.conf &
wait

ocpasswd -c /etc/ocserv/ocpasswd $USER_NAME &
#ipnut password
#input password
wait

systemctl enable ocserv.service &
wait

systemctl mask ocserv.socket &
wait

cp /lib/systemd/system/ocserv.service /etc/systemd/system/ocserv.service &
wait

sed -i 's/Requires=ocserv.socket/#Requires=ocserv.socket/' /etc/systemd/system/ocserv.service
sed -i 's/Also=ocserv.socket/#Also=ocserv.socket/' /etc/systemd/system/ocserv.service

systemctl daemon-reload &
wait
systemctl stop ocserv.socket > /dev/null &
wait
systemctl disable ocserv.socket > /dev/null &
wait
systemctl restart ocserv.service > /dev/null &
wait
systemctl status ocserv.service

apt install iptables-persistent -y &
#input ok 
#input ok

wait

iptables-save > /etc/iptables.rules &
wait

systemctl status ocserv.service
