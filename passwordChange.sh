#! /bin/bash
echo "$1"
for entry in $(awk -F: '{if($7 != "/bin/false")if($7 != "/usr/sbin/nologin")if($7 != "/bin/sync")if($7 != "/bin/false") print $1;}' /etc/passwd); do
    echo "Change passwd for $entry ?"
    select yn in "Yes" "No"; do
        case $yn in 
            Yes ) echo "Changed"; echo "${entry}:${1}" | chpasswd; break;;
	    No ) echo "Not Changed"; break;;
        esac
    done
done
