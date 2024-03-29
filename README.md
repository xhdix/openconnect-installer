# Automatically set up an Openconnect VPN server(ocserv) with Let's Encrypt with just one command.

* Secured with a valid certificate from Let's encrypt
* No IP Leak
* No DNS Leak
* No request/send from/to external/third party sources

All you need: A CentOS 8 server with a domain.

Note 05/09/2021: If you had any problem, disable UDP and do not use the Anyconnect client app for a while!

Note 23/09/2021: Change the server or server IP every 3 months to prevent Google from tracking and [flagging your server's IP](https://gitlab.torproject.org/tpo/anti-censorship/censorship-analysis/-/issues/22369).

## Install, configure, run with one command:

Change the username-password list `pass.txt` (or create a new one) and then just run the command like this :

```bash
bash install.sh -f username-list-file -n host-name -e email-address
```

for example :
```bash
bash install.sh -f pass.txt -n my.example.com -e mayemail@gmail.com
```

Note: By changing the script, you can get a certificate without an email address. But it is better not to.
(`--email $EMAIL_ADDR` to `--register-unsafely-without-email`)

-------------------
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

![Bypass the Internet blackout](https://user-images.githubusercontent.com/12384263/140075673-aa31959b-0979-4abc-9fea-dd89a73009d7.png)

(reference: https://ooni.org/post/2019-iran-internet-blackout/#connecting-to-the-internet-from-iran)

After installing Openconnect on a foreign VPS, just enter these commands on the domestic VPS:
```bash
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -t nat -A PREROUTING -i eth0 -p tcp -m tcp --dport 443 -j DNAT  --to-destination [foreignVPSip]:443
iptables -t nat -A PREROUTING -i eth0 -p udp -m udp --dport 443 -j DNAT  --to-destination [foreignVPSip]:443
iptables -t nat -A PREROUTING -i eth0 -p udp -m udp --dport 53 -j DNAT  --to-destination [foreignVPSip]:53
iptables -t nat -A POSTROUTING -o eth0 -j SNAT --to-source [domesticVPSip]


```
_(Note: Make sure you use the correct network interface name. e.g. eth0 or enp0s3 or ... )_

Then save iptables:
```bash
yum install iptables-services -y

systemctl enable iptables

service iptables save

systemctl start iptables
```

And then use Openconnect like this:
```bash
echo password|openconnect --resolve=domain.com:[domesticVPSip] -vu username --passwd-on-stdin https://domain.com
```
Or temporary change `A` record to domestic VPS ip.

**Note: The amount of incoming and outgoing traffic on your domestic VPS should not be equal.**

**Please let me know if there is any problem.**
