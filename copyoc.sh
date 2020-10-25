#!/bin/bash
# Run two copies of ocserv on the same server
# bash ./copyoc.sh -p <port> [--family]
# bash ./copyoc.sh --tcp-port <port> [--family]
# bash ./copyoc.sh --tcp-port <port> --udp-port <port> [--family]
#
# For update files only:
# bash ./copyoc.sh -u <port/tcp-port>


usage()
{
    echo "usage:"
    echo "bash ./copyoc.sh -p <port> [--family]"
    echo "bash ./copyoc.sh --tcp-port <port> [--family]"
    echo "bash ./copyoc.sh --tcp-port <port> --udp-port <port> [--family]"
    echo "bash ./copyoc.sh -u <port>"
}

FAMILY=false
PORT=
TPORT=
UPORT=
UPDATE=

while [[ $1 != "" ]]; do
    case $1 in
        -f | --family )     shift
			        FAMILY=true
                                ;;
        -p | --port )     shift
			        PORT=$1
                                ;;
        --tcp-port )     shift
			        TPORT=$1
                                ;;
        --udp-port )     shift
			        UPORT=$1
                                ;;
        -u | --update )      shift
			        UPDATE=$1
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

if [[ $PORT == "443" ]] || [[ $TPORT == "443" ]] || [[ $UPORT == "443" ]] ; then
  echo "If you changed the install.sh code, you need to change this as well! :)"
  exit
fi

if [[ ! $UPDATE ]] ; then
  POSTFIX="2"
  if [[ $PORT == "" ]] && [[ $TPORT == "" ]] && [[ $UPORT == "" ]] ; then
    PORT=2083
    POSTFIX="$PORT"
    cp -f /etc/ocserv/ocserv.conf /etc/ocserv/ocserv$POSTFIX.conf &
    wait
    sed -i "s/tcp-port = 443/tcp-port = 2083/" /etc/ocserv/ocserv$POSTFIX.conf
    sed -i "s/udp-port = 443/#udp-port = 443/" /etc/ocserv/ocserv$POSTFIX.conf
    iptables -I INPUT -p tcp --dport 2083 -j ACCEPT &
  elif [[ $PORT != "" ]] && [[ $TPORT == "" ]] && [[ $UPORT == "" ]] ; then
    POSTFIX="$PORT"
    cp -f /etc/ocserv/ocserv.conf /etc/ocserv/ocserv$POSTFIX.conf &
    wait
    sed -i "s/tcp-port = 443/tcp-port = $PORT/" /etc/ocserv/ocserv$POSTFIX.conf
    sed -i "s/udp-port = 443/udp-port = $PORT/" /etc/ocserv/ocserv$POSTFIX.conf
    iptables -I INPUT -p tcp --dport $PORT -j ACCEPT &
    iptables -I INPUT -p udp --dport $PORT -j ACCEPT &
  elif [[ $PORT == "" ]] && [[ $TPORT != "" ]] && [[ $UPORT != "" ]] ; then
    POSTFIX="$TPORT"
    cp -f /etc/ocserv/ocserv.conf /etc/ocserv/ocserv$POSTFIX.conf &
    wait
    sed -i "s/tcp-port = 443/tcp-port = $TPORT/" /etc/ocserv/ocserv$POSTFIX.conf
    sed -i "s/udp-port = 443/udp-port = $UPORT/" /etc/ocserv/ocserv$POSTFIX.conf
    iptables -I INPUT -p tcp --dport $TPORT -j ACCEPT &
    iptables -I INPUT -p udp --dport $UPORT -j ACCEPT &
  elif [[ $PORT == "" ]] && [[ $TPORT != "" ]] && [[ $UPORT == "" ]] ; then
    POSTFIX="$TPORT"
    cp -f /etc/ocserv/ocserv.conf /etc/ocserv/ocserv$POSTFIX.conf &
    wait
    sed -i "s/tcp-port = 443/tcp-port = $TPORT/" /etc/ocserv/ocserv$POSTFIX.conf
    sed -i "s/udp-port = 443/#udp-port = 443/" /etc/ocserv/ocserv$POSTFIX.conf
    iptables -I INPUT -p tcp --dport $TPORT -j ACCEPT &
  elif [[ $PORT == "" ]] && [[ $TPORT == "" ]] && [[ $UPORT != "" ]] ; then
    echo "there is no way to set UDP only"
    exit
  fi

  sed -i "s/socket-file = ocserv.sock/socket-file = ocserv$POSTFIX.sock/" /etc/ocserv/ocserv$POSTFIX.conf
  sed -i "s/chroot-dir = \/var\/lib\/ocserv/chroot-dir = \/var\/lib\/ocserv$POSTFIX/" /etc/ocserv/ocserv$POSTFIX.conf
  sed -i "s/pid-file = \/var\/run\/ocserv.pid/pid-file = \/var\/run\/ocserv$POSTFIX.pid/" /etc/ocserv/ocserv$POSTFIX.conf
  sed -i 's/device = vpns/device = vpn'"$POSTFIX"'s/' /etc/ocserv/ocserv$POSTFIX.conf
  sed -i "s/ipv4-network = 192.168.128.0/ipv4-network = 192.168.1${POSTFIX: -2}.0/" /etc/ocserv/ocserv$POSTFIX.conf

  if [[ $FAMILY ]] ; then
    sed -i "s/dns = 1.1.1.1/dns = 1.1.1.3/" /etc/ocserv/ocserv$POSTFIX.conf
    sed -i "s/dns = 8.8.8.8/dns = 1.0.0.3/" /etc/ocserv/ocserv$POSTFIX.conf
  fi

  cp -f /var/run/ocserv.pid /var/run/ocserv$POSTFIX.pid
  cp -f /usr/sbin/ocserv-worker /usr/sbin/ocserv$POSTFIX-worker
  cp -f /usr/sbin/ocserv-genkey /usr/sbin/ocserv$POSTFIX-genkey
  cp -f /usr/sbin/ocserv /usr/sbin/ocserv$POSTFIX

  cp -rf  /var/lib/ocserv  /var/lib/ocserv$POSTFIX &
  wait

  cp -f /etc/systemd/system/ocserv.service /etc/systemd/system/ocserv$POSTFIX.service &
  wait

  sed -i "s/PIDFile=\/var\/run\/ocserv.pid/PIDFile=\/var\/run\/ocserv$POSTFIX.pid/" /etc/systemd/system/ocserv$POSTFIX.service &
  sed -i "s/ExecStartPre=\/usr\/sbin\/ocserv-genkey/ExecStartPre=\/usr\/sbin\/ocserv$POSTFIX-genkey/" /etc/systemd/system/ocserv$POSTFIX.service &
  sed -i "s/ExecStart=\/usr\/sbin\/ocserv --pid-file \/var\/run\/ocserv.pid --config \/etc\/ocserv\/ocserv.conf -f/ExecStart=\/usr\/sbin\/ocserv$POSTFIX --pid-file \/var\/run\/ocserv$POSTFIX.pid --config \/etc\/ocserv\/ocserv$POSTFIX.conf -f/" /etc/systemd/system/ocserv$POSTFIX.service &
  wait

  systemctl daemon-reload &
  wait

  systemctl enable ocserv$POSTFIX &
  wait

  iptables -A FORWARD -d 192.168.1${POSTFIX: -2}.0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT &
  iptables -A FORWARD -s 192.168.1${POSTFIX: -2}.0 -j ACCEPT &
  wait
  
  service iptables save &
  wait

  systemctl restart ocserv$POSTFIX &
  wait

  echo "done!"

  journalctl -u ocserv$POSTFIX
  
elif [[ $UPDATE != "" ]] ; then
  POSTFIX="$UPDATE"
  # cp -f /etc/ocserv/ocserv.conf /etc/ocserv/ocserv$POSTFIX.conf &
  # wait
  
  cp -f /var/run/ocserv.pid /var/run/ocserv$POSTFIX.pid
  cp -f /usr/sbin/ocserv-worker /usr/sbin/ocserv$POSTFIX-worker
  cp -f /usr/sbin/ocserv-genkey /usr/sbin/ocserv$POSTFIX-genkey
  cp -f /usr/sbin/ocserv /usr/sbin/ocserv$POSTFIX

  cp -rf  /var/lib/ocserv  /var/lib/ocserv$POSTFIX &
  wait
  
  echo "done!"
  echo "now run: systemctl restart ocserv$POSTFIX"
fi
