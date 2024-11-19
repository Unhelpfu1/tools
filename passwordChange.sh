#! /bin/bash
for entry in $(awk -F: '{if($7 != "/bin/false")if($7 != "/usr/sbin/nologin")if($7 != "/bin/sync")if($7 != "/bin/false") print $1;}' /etc/passwd); do # if they can log in
    echo "Change passwd for $entry ?"
    select yn in "Yes" "No"; do # ask if you want to change their password
        case $yn in 
            Yes ) echo "Changed"; echo "${entry}:${1}" | chpasswd; break;;
	    No ) echo "Not Changed"; break;;
        esac
    done
done
echo "$1" #tells you the password you just changed everything to
