#!/bin/bash
# copy ocserv with only with tcp config on port 2083
#
cp -f /etc/ocserv/ocserv.conf /etc/ocserv/ocserv2.conf &
wait


sed -i 's/tcp-port = 443/tcp-port = 2083/' /etc/ocserv/ocserv2.conf
sed -i 's/udp-port = 443/#udp-port = 443/' /etc/ocserv/ocserv2.conf
sed -i 's/socket-file = ocserv.sock/socket-file = ocserv2.sock/' /etc/ocserv/ocserv2.conf
sed -i 's/chroot-dir = \/var\/lib\/ocserv/chroot-dir = \/var\/lib\/ocserv2/' /etc/ocserv/ocserv2.conf
sed -i 's/switch-to-tcp-timeout = 25/switch-to-tcp-timeout = 1/' /etc/ocserv/ocserv2.conf
sed -i 's/pid-file = \/var\/run\/ocserv.pid/pid-file = \/var\/run\/ocserv2.pid/' /etc/ocserv/ocserv2.conf
sed -i 's/device = vpns/device = vpn2s/' /etc/ocserv/ocserv2.conf
sed -i 's/ipv4-network = 192.168.128.0/ipv4-network = 192.168.127.0/' /etc/ocserv/ocserv2.conf


cp -f /var/run/ocserv.pid /var/run/ocserv2.pid
cp -f /usr/sbin/ocserv-worker /usr/sbin/ocserv2-worker
cp -f /usr/sbin/ocserv-genkey /usr/sbin/ocserv2-genkey
cp -f /usr/sbin/ocserv /usr/sbin/ocserv2

cp -rf  /var/lib/ocserv  /var/lib/ocserv2 &
wait

cp -f /etc/systemd/system/ocserv.service /etc/systemd/system/ocserv2.service &
wait

sed -i 's/PIDFile=\/var\/run\/ocserv.pid/PIDFile=\/var\/run\/ocserv2.pid/' /etc/systemd/system/ocserv2.service &
sed -i 's/ExecStartPre=\/usr\/sbin\/ocserv-genkey/ExecStartPre=\/usr\/sbin\/ocserv2-genkey/' /etc/systemd/system/ocserv2.service &
sed -i 's/ExecStart=\/usr\/sbin\/ocserv2 --pid-file \/var\/run\/ocserv2.pid --config \/etc\/ocserv\/ocserv2.conf -f/ExecStart=\/usr\/sbin\/ocserv2 --pid-file \/var\/run\/ocserv2.pid --config \/etc\/ocserv\/ocserv2.conf -f/' /etc/systemd/system/ocserv2.service &
wait

systemctl daemon-reload &
wait

systemctl enable ocserv2 &
wait

iptables -I INPUT -p tcp --dport 2083 -j ACCEPT
iptables -A FORWARD -d 192.168.127.0/21 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

service iptables save &
wait


systemctl restart ocserv2 &
wait



journalctl |grep ocserv2
