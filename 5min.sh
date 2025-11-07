#!/bin/bash

MENU=true
SAVED=""

while ["$MENU" = "true"]
do
    #Clear terminal
    Clear

    # Print a value which wont be cleared by the terminal
    echo "$SAVED"

    # List all options
    echo "[0] Quit"
    echo "[1] Change passwords"
    echo "[2] Delete accounts"

    # Prompt user for input and grab input
    read -p "Please select an option: " OPTION
    echo $OPTION #DEBUG

    # Quit option
    if ["$OPTION" = "0"]; then
        exit 0
    fi

    # Change Passwords option
    if ["$OPTION" = "1"]; then
        changePasswords
    fi

    # Delete any accounts
    if ["$OPTION" = "0"]; then
        deleteAccounts
    fi
done

# Change passwords of all selected accounts to whatever is specified at the start
function changePasswords() {
    read -p "Enter the password to set: " PASSWORD
    # Any account which can log in
    for ENTRY in $(awk -F: '{if($7 != "/bin/false" && $7 != "/usr/sbin/nologin" && $7 != "/bin/sync") print $1;}' /etc/passwd); do
        echo "Change password for ${ENTRY}?"
        select yn in "Yes" "No"; do # ask if you want to change their password
            case $yn in 
                "Yes") echo "Changed"; echo "${ENTRY}:${PASSWORD}" | chpasswd; break;; # Inform user and change password
	            "No")  echo "Not Changed"; break;; # Inform user password was not changed
            esac
        done
    done
    echo "$PASSWORD" #tells you the password you just changed everything to
    SAVED="Passwords changed to: $PASSWORD"
}

# Run through each user and decide whether to delete them or not
function deleteAccounts() {
    DELETED=""
    echo "$(cat /etc/passwd)"
    while IFS= read -r ENTRY; do
    # Grab the username for later reference
        USERNAME=$(echo "$ENTRY" | cut -d: -f1)
        # Print the line being referenced
        echo "Current User:"
        echo "${ENTRY}"
        echo "Delete user?"
        select yn in "Yes" "No"; do
            case $yn in
                "Yes") echo "Are you sure?"
                    # 2nd chance to cancel deletion
                    select CONFIRM in "Yes, Delete this user" "No"; do
                        case $CONFIRM in
                             "Yes, Delete this user") DELETED="$DELETED $USERNAME"; userdel -r "$USERNAME"; break;;
                             "No") echo "NOT deleted"; break;;
                        esac
                    done; break;;
                "No") echo "Not deleted"; break;;
            esac
        done
    done < /etc/passwd
    SAVED="Selected users deleted: $DELETED"
}
