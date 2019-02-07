#!/bin/bash
# pre-alpha version for openconnect installer in Debian
#
# bash ocsi.sh -i your-server-IP -u first-username -c certificate-name -o organization-name

usage()
{
    echo "usage:"
    echo "bash ocsi.sh -i your-server-IP -u first-username -c certificate-name -o organization-name"
    ##echo "usage: sysinfo_page [[[-i ip ] [-u username] [-c certname ] [-o orgname]] | [-h]]"
}


###### Main

SERVER_IP=`ip addr show | awk '/inet/ {print $2}' | grep -v "127.0.0.1" | grep -v "::" | cut -f1 -d"/"`
USER_NAME="testuser"
SERVICE_NAME="service"
ORG_NAME="organization"

while [[ $1 != "" ]]; do
    case $1 in
        -i | --ip )           shift
			        SERVER_IP=$1
                                ;;
        -u | --username )     shift
			        USER_NAME=$1
                                ;;
        -c | --certname )     shift
			        SERVICE_NAME=$1
                                ;;
        -o | --orgname )      shift
			        ORG_NAME=$1
                                ;;
        -h | --help )         usage
                                exit
                                ;;
        * )                   usage
                                exit 1
    esac
    echo $1;
    shift
done

if [[ $SERVER_IP == "" ]] ; then
  usage
  exit
fi

echo 
echo "LC_ALL=en_US.UTF-8" >> /etc/environment
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
sh -c "echo 'LC_ALL=en_US.UTF-8\nLANG=en_US.UTF-8' >> /etc/environment"

cat > /etc/default/locale << "EOF"
LANGUAGE=en_US.UTF-8,
LC_ALL=en_US.UTF-8,
LC_MONETARY=en_US.UTF-8,
LC_ADDRESS=en_US.UTF-8,
LC_TELEPHONE=en_US.UTF-8,
LC_NAME=en_US.UTF-8,
LC_MEASUREMENT=en_US.UTF-8,
LC_IDENTIFICATION=en_US.UTF-8,
LC_NUMERIC=en_US.UTF-8,
LC_PAPER=en_US.UTF-8,
LANG=en_US.UTF-8
EOF

export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
locale-gen en_US en_US.UTF-8
dpkg-reconfigure locales
#input ok
#input ok


locale
update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
#apt install language-pack-en-base  

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
sed -i 's/ipv4-network = 192.168.1.0/ipv4-network = 192.168.128.0/' /etc/ocserv/ocserv.conf
sed -i 's/#mtu = 1420/mtu = 1420/' /etc/ocserv/ocserv.conf
sed -i 's/#route = default/route = default/' /etc/ocserv/ocserv.conf
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

#reboot

#apt install fail2ban lynis bmon clamav clamav-daemon aide -y
