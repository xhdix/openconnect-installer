#!/bin/bash
# bash ./familyuser.sh username

if grep -Fxq '#config-per-user = /etc/ocserv/config-per-user/' /etc/ocserv/ocserv.conf ; then

  sed -i "s/#config-per-user = \/etc\/ocserv\/config-per-user\//config-per-user = \/etc\/ocserv\/config-per-user\//" /etc/ocserv/ocserv.conf &
  wait


  mkdir -p /etc/ocserv/config-per-user/ &
  wait


  echo "
  dns = 1.0.0.3
  dns = 1.1.1.3
  " >  /etc/ocserv/config-per-user/$1 &
  wait


  echo "done!"
  echo "now run: systemctl restart ocserv"

else


  echo "
  dns = 1.0.0.3
  dns = 1.1.1.3
  " >  /etc/ocserv/config-per-user/$1 &
  wait
  
  echo "done!"

fi
