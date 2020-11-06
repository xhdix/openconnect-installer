# Automatically set up an Openconnect VPN server(ocserv) with Let's Encrypt with just one command.

* Secured with a valid certificate from Let's encrypt
* No IP Leak
* No DNS Leak
* No request/send from/to external/third party sources

All you need: A CentOS 8 server with a domain.

### Install, configure, run with one command:
```bash
bash install.sh -f username-list-file -n host-name -e email-address

e.g. :

bash install.sh -f pass.txt -n my.example.com -e info@gmail.com
```

#### If you want to add a list of users again after installation:
```bash
bash adduser.sh username-list-file

e.g. :
bash adduser.sh pass2.text
```
#### Renew the certificate before/after 3 months:

```bash
certbot renew --quiet && systemctl restart ocserv # && systemctl restart ocserv2
```
### Run two copies of `ocserv` on the same server
Do you want to run `ocserv` on a new port with a different configuration? Take a look at `copyoc.sh`.

#### New `ocserv` copy
```bash
 bash ./copyoc.sh -p <port>

e.g. :
bash ./copyoc.sh -p 8443
```

#### New `ocserv` copy for families (Cloudflare DNS for families)
Will block malware and adult content in the new VPN service
```bash
 bash ./copyoc.sh -p <port> -f
 
 e.g. :
 bash ./copyoc.sh -p 2222 -f
```

## Bypass the Internet blackout

![image](https://ooni.org/post/2019-iran-internet-blackout/11.png)
(reference: https://ooni.org/post/2019-iran-internet-blackout/#connecting-to-the-internet-from-iran)

After installing Openconnect on a foreign VPS, just enter these commands on the domestic VPS:
(Note: Make sure you use the correct network interface name. e.g. eth0 or enp0s3 or ... )
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
