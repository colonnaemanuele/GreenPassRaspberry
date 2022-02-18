#!/bin/bash

while true; do
  killall feh
  
  # wait for camera movement
  motion 2>&1 > /dev/null

  data=$(timeout 10 zbarcam -q1 --raw 2>/dev/null | grep HC1)
  feh --hide-pointer -x -q -B black ~/green/green-loading.png &  
  
  # check valid raw data
  if [ "$data" ]; then
    green=$(echo $data | greenpass --txt -)
    
    checked=$(echo "$green" | grep "Verificato" | awk '{print $2}')
    locked=$(echo "$green" | grep "Bloccato" | awk '{print $2}')
    expired=$(echo "$green" | grep "Scaduto da")
    name=($(echo "$green" | egrep "Nome|Cognome" | awk '{print $2}'))
    birth=$(echo "$green" | grep "Data di Nascita" | awk '{print $4}')
    
    if [ "$checked"=="Sì" ] && [ "$locked"=="No" ] && [ -z "$expired" ]; then
      echo "QR valido"
      feh --hide-pointer -x -q -B black --font "yudit/16" --info "printf '%%67s%%s\n\n%%67s%%s\n\n\n' '' '${name[*]}' '' '$birth'"  ~/green/green-ok.png &
    else
      echo "QR non valido"
      feh --hide-pointer -x -q -B black --font "yudit/16" --info "printf '%%67s%%s\n\n%%67s%%s\n\n\n' '' '${name[*]}' '' '$birth'"  ~/green/green-no.png &
    fi
    
  else
    echo "lettura errata"
    feh --hide-pointer -x -q -B black ~/green/green-fail.png &
  fi

  sleep 3
done
