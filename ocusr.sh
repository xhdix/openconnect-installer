#!/bin/bash
#bash ocusr.sh list-file-name
LIST=$1
if [[ $LIST != "" ]] ; then
  while read -r -a line; do
          echo "For user ${line[0]} password is update with ${line[1]}"
    echo "${line[1]}" | ocpasswd -c /etc/ocserv/ocpasswd "${line[0]}"
  done < $LIST
  exit
fi
