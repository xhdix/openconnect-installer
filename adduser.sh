#!/bin/bash
#bash adduser.sh list-file-name
LIST=$1
if [[ $LIST == "" ]] ; then
  echo "bash adduser.sh list-file-name"
  exit
else
  while read -r -a line; do
    if [[ "${line[0]}" != "" ]] ; then
    echo "For user ${line[0]} password updated with ${line[1]}"
    echo "${line[1]}" | ocpasswd -c /etc/ocserv/ocpasswd "${line[0]}"
    fi
  done < $LIST
  exit
fi
