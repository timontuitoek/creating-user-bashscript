#!/bin/bash

LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.csv"

# Check if the input file is provided and exists
if [ -z "$1" ] || [ ! -f "$1" ]; then
  echo "Usage: $0 <name-of-text-file>" | tee -a $LOG_FILE
  exit 1
fi

INPUT_FILE="$1"

# Prepare the password file with appropriate permissions
touch $PASSWORD_FILE
chmod 600 $PASSWORD_FILE

while IFS= read -r line; do
  username=$(echo $line | cut -d ';' -f 1 | xargs)
  groups=$(echo $line | cut -d ';' -f 2 | tr ',' ' ' | xargs)

  # Create user with a personal group
  if ! id "$username" &>/dev/null; then
    useradd -m -U "$username"
    echo "User created: $username" | tee -a $LOG_FILE

    # Generate and set password
    password=$(openssl rand -base64 12)
    echo "$username:$password" | chpasswd
    echo "$username,$password" >> $PASSWORD_FILE
  fi

  # Create and assign groups
  for group in $groups; do
    if ! getent group "$group" &>/dev/null; then
      groupadd "$group"
      echo "Group created: $group" | tee -a $LOG_FILE
    fi
    usermod -aG "$group" "$username"
  done
done < "$INPUT_FILE"
