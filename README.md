# openconnect-installer
Openconnect installer - Pre-Alpha in Debian and CentOS

```
bash ocserv-deb*.sh -f username-list-file -n host-name -e email-address
bash ocserv-cen*.sh -f username-list-file -n host-name -e email-address

e.g. :

bash ocserv-deb*.sh -f UserPwdList -n my.example.com -e info@gmail.com
```

# Bypass the Internet blackout

![image](https://ooni.org/post/2019-iran-internet-blackout/11.png)
(reference: https://ooni.org/post/2019-iran-internet-blackout/#connecting-to-the-internet-from-iran)

After installing Openconnect on a foreign VPS, just enter these commands on the domestic VPS:
```bash
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -t nat -A PREROUTING -i eth0 -p tcp -m tcp --dport 443 -j DNAT  --to-destination [foreignVPSip]:443
iptables -t nat -A PREROUTING -i eth0 -p udp -m udp --dport 443 -j DNAT  --to-destination [foreignVPSip]:443
iptables -t nat -A PREROUTING -i eth0 -p udp -m udp --dport 53 -j DNAT  --to-destination [foreignVPSip]:53
iptables -t nat -A POSTROUTING -o eth0 -j SNAT --to-source [domesticVPSip]

```
And then use Openconnect like this:
```bash
echo password|openconnect --resolve=domain.com:[domesticVPSip] -vu username --passwd-on-stdin https://domain.com
```
