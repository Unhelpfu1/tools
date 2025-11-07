#!/bin/bash

MENU=true
SAVED=""

function main() {
    while [ "${MENU}" = "true" ]; do
        #Clear terminal
        clear

        # Print a value which wont be cleared by the terminal
        echo -e "${SAVED}"

        # List all options
        echo "[0] Quit"
        echo "[1] Change passwords"
        echo "[2] Delete accounts"
        echo "[3] Find SSH Keys"
        echo "[4] Scan /var/auth.log"

        # Prompt user for input and grab input
        read -p "Please select an option: " OPTION
        echo ${OPTION} #DEBUG

        # Quit option
        if [ "${OPTION}" = "0" ]; then
            MENU="false" # Unnecessary lol
            exit 0
        fi

        # Change Passwords option
        if [ "${OPTION}" = "1" ]; then
            changePasswords
        fi

        # Delete any accounts
        if [ "${OPTION}" = "2" ]; then
            deleteAccounts
        fi

        # Find SSH keys and show user
        if [ "${OPTION}" = "3" ]; then
            findSSHKeys
        fi

        # Search for any sshd interactions or sudo usage
        if [ "${OPTION}" = "4" ]; then
            authTracking
        fi
    done
}

# Change passwords of all selected accounts to whatever is specified at the start
function changePasswords() {
    CHANGED=""
    read -p "Enter the password to set: " PASSWORD
    # Any account which can log in
    awk -F: '{if($7 != "/bin/false" && $7 != "/usr/sbin/nologin" && $7 != "/bin/sync") print $1;}' /etc/passwd | while read ENTRY; do
        echo "Change password for ${ENTRY}?"
        select yn in "Yes" "No"; do # ask if you want to change their password
            case $yn in 
                "Yes") echo "Changed"; CHANGED="${CHANGED} ${ENTRY}"; echo "${ENTRY}:${PASSWORD}" | chpasswd; break;; # Inform user and change password
	            "No")  echo "Not Changed"; break;; # Inform user password was not changed
            esac
        done
    done
    echo "$PASSWORD" #tells you the password you just changed everything to
    SAVED="Passwords changed to: ${PASSWORD}\nUsers Impacted: ${CHANGED}"
    echo -e "$(date):\n${CHANGED}" >> ${HOME}/passwordsChanged.log

    #Change PASSWORD back to "" so that it cant be read as easily
    PASSWORD=""
}

# Run through each user and decide whether to delete them or not
function deleteAccounts() {
    DELETED=""
    DELETEDfullLine=""
    echo "$(cat /etc/passwd)"
    while IFS= read -r ENTRY; do
        # Grab the username for later reference
        USERNAME=$(cut -d: -f1 <<< "$ENTRY")
        if [[ "${USERNAME}" != "root"* && "${USERNAME}" != *"white"* && "${USERNAME}" != *"gray"* && "${USERNAME}" != *"black"* && "${USERNAME}" != *"dog"* ]]; then
            # Print the line being referenced
            echo "Current User:"
            echo "${ENTRY}"
            echo "Delete user?"
            select yn in "Yes" "No"; do
                case $yn in
                    "Yes") echo "Are you sure?"
                        # 2nd chance to cancel deletion
                        select CONFIRM in "Yes, Delete this user" "No"; do
                            case ${CONFIRM} in
                                "Yes, Delete this user") DELETEDfullLine="${DELETEDfullLine}\n${ENTRY}"; DELETED="${DELETED} ${USERNAME}"; userdel -r "${USERNAME}"; echo "${USERNAME} deleted"; break;;
                                "No") echo "NOT deleted"; break;;
                            esac
                        done; break;;
                    "No") echo "Not deleted"; break;;
                esac
            done
        fi
    done < /etc/passwd
    SAVED="Selected users deleted: ${DELETED}"
    echo -e "$(date):${DELETEDfullLine}" >> ${HOME}/deletedAccounts.log
}

# Find and print all public ssh keys found
function findSSHKeys() {
    #Search for any .pub file on the system, throw out errors
    PATHS=$(find / -type f -name "*.pub" 2>/dev/null) 
    SAVED="SSH Key Paths found:\n${PATHS}"
    echo -e "$(date):\n${PATHS}" >> ${HOME}/SSHKeyLocation.log
}

# Check for interactions with sshd or sudo and log them independently
function authTracking() {
    if [ -e /var/auth.log ]; then
        # Look for sshd interactions and log them
        grep -E "sshd.*Failed password|sshd.*Accepted" /var/auth.log | \
        awk '{for(i=1;i<=NF;i++) if($i=="for" || $i=="user" || $i=="from") print $(i+1)}' | \
        sort | uniq | while read -r ATTEMPT; do
            # Check if attempt is already logged
            if ! grep -q "${ATTEMPT}" "${HOME}/sshdInteractions.log"; then
                echo "${ATTEMPT}"
                # Save to log file
                echo "${ATTEMPT}" >> "${HOME}/sshdInteractions.log"
            fi
        done

        # Look for sudo interactions
        grep "sudo" /var/auth.log | awk '{print $1, $2, $3, $0}' | sort | uniq | while read -r ATTEMPT; do
            # Check if the line is already logged
            if ! grep -F "${ATTEMPT}" "${HOME}/sudoCommands.log" > /dev/null; then
                echo "${ATTEMPT}"
                # Save to log file
                echo "${ATTEMPT}" >> "${HOME}/sudoCommands.log"
            fi
        done
        SAVED="New entries logged"
    else
        SAVED="/var/auth.log could not be found"
    fi
}

# Call what was defined as main at the top of the script
main
