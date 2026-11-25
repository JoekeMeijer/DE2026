#!/bin/bash
set -e

USERNAME="assignment"

# Create the user non-interactively with a home directory and bash shell
if id "$USERNAME" &>/dev/null; then
    echo "User '$USERNAME' already exists."
else
    useradd -m -s /bin/bash "$USERNAME"
    echo "User '$USERNAME' created."
fi

# Add the user to the sudo group (and docker group if it exists)
usermod -aG sudo "$USERNAME"
if getent group docker &>/dev/null; then
    usermod -aG docker "$USERNAME"
fi

# Grant passwordless sudo without interactive prompts
SUDOERS_FILE="/etc/sudoers.d/$USERNAME"
echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > "$SUDOERS_FILE"
chmod 0440 "$SUDOERS_FILE"

# Validate the sudoers file syntax
visudo -cf "$SUDOERS_FILE"

echo "Done! '$USERNAME' is ready to use! Copy this Git to the assignment home folder and run the startup script! :) "
