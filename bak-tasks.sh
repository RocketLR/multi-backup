#!/bin/sh
DIRECTORY=`dirname $0`
logfile="backup.log"

devices=$(jq -r '.backup' "$DIRECTORY""/""devices.json")

for row in $(echo "${devices}" | jq -r '.[] | @base64'); do
    # each value needs to be decoded from base64 beacuse some characters can cause the issues and then printed out using jq command again. Now each value can be requested seperatly. 
    _jq()
    {
     echo ${row} | base64 --decode | jq -r ${1}
    }

    # test this by giving a device wrong addr. 
    ping -W 2 -c 1 $(_jq '.addr') 1> /dev/null 2>> "$DIRECTORY""/$logfile"
    # This checks to see if the ping went well, meaning it checkd that the name is resolvable and also reachable. if not skip.
    if [[ $? == 0 ]]; then


    # Check wich method to use, incase future methods are added.
    case $(_jq '.meth') in
      # Handle empty addresses.
    "")
        echo "$(_jq '.addr') empty method"
        ;;

        # Cisco nexus switches
    ssh)
        echo "SSH!"
        
         #Result=$(
         Result=$(ssh -oStrictHostKeyChecking=no -oBatchMode=yes "$(_jq '.username')""@""$(_jq '.addr')" "show run" 2> /dev/null)
         echo "$Result" > "$DIRECTORY""/""$(_jq '.dstfile')_$(date +"%y%m%d")$(_jq '.ext')"

        ;;
        # HP Procuve 5830 Switches
    hp5830)
        echo "triggering backup with method hp5830 and sshpass on device $(_jq '.addr')"
        # example of the command it send to the device: backup startup-configuration to 192.168.228.100 rlg-slave-sw-01.cfg
        echo $(_jq '.pass') | /mnt/pool1/iocage/jails/applications/root/usr/local/bin/sshpass ssh -oStrictHostKeyChecking=no "$(_jq '.username')""@""$(_jq '.addr')" "backup startup-configuration to 192.168.228.100 $(_jq '.dstfile')$(_jq '.ext')" 2>> "$DIRECTORY""/$logfile"

        ;;
		
		hp5830dss)
        echo "triggering backup with method hp5830 and sshpass on device $(_jq '.addr')"
        # example of the command it send to the device: backup startup-configuration to 192.168.228.100 rlg-slave-sw-01.cfg
        echo $(_jq '.pass') | /mnt/pool1/iocage/jails/applications/root/usr/local/bin/sshpass ssh -oHostKeyAlgorithms=+ssh-dss -oStrictHostKeyChecking=no "$(_jq '.username')""@""$(_jq '.addr')" "backup startup-configuration to 192.168.228.100 $(_jq '.dstfile')$(_jq '.ext')" 2>> "$DIRECTORY""/$logfile"

        ;;
        # Fortigate Routers
    fortigate)
      echo "triggering backupp with method fortigate and sshpass on device $(_jq '.addr')"
      # example of the command it sends to the device: execute backup config tftp ivovpn.conf 192.168.228.100

      echo $(_jq '.pass') | /mnt/pool1/iocage/jails/applications/root/usr/local/bin/sshpass ssh -oStrictHostKeyChecking=no "$(_jq '.username')""@""$(_jq '.addr')" "execute backup config tftp $(_jq '.dstfile')$(_jq '.ext') 192.168.228.100" 2>> "$DIRECTORY""/$logfile"

      ;;

      *)
      echo "Unknown method: $(_jq '.meth')"
      ;;     
    esac

  else
    echo "Destination is unreachable or hostname unresolvable: $(_jq '.addr')"
  fi 

done



exit 0