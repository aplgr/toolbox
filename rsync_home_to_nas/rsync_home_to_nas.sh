#!/bin/bash

# Default value for .env file
DEFAULT_ENV_FILE="/home/${SUDO_USER}/.env"
ENV_FILE="$DEFAULT_ENV_FILE"
SKIP_INTERACTIVE=false
QUIET_MODE=false

# Function for error exit
function error_exit {
    echo "$1" 1>&2
    exit 1
}

# Function to display usage information
function usage {
    echo "Usage: $0 [-f] [-q] [-h] [config_file]"
    echo "  -f              Skip interactive prompts and use values from the config file."
    echo "  -q              Quiet mode; suppress all output except errors."
    echo "  -h              Display this help message."
    echo "  config_file      Path to the configuration file (default: $DEFAULT_ENV_FILE)."
    exit 0
}

# Function to output messages only if not in quiet mode
function log {
    if [ "$QUIET_MODE" = false ]; then
        echo "$1"
    fi
}

# Prompt for confirmation or modification of a variable
function confirm_or_modify {
    local var_name=$1
    local var_value=$2
    local input

    # If interactive mode is skipped, just use the existing value
    if [ "$SKIP_INTERACTIVE" = true ]; then
        return
    fi

    # Ask for confirmation of variable, except for password
    if [ "$var_name" == "PASSWORD" ]; then
        read -s -p "Current password is set. Press Enter to keep it or enter a new password: " input
        echo
    else
        read -p "Current value for $var_name [$var_value]: " input
    fi

    # Replace the old value with the new one if user input is provided
    if [ ! -z "$input" ]; then
        eval "$var_name=\"$input\""
    fi
}

# Function to unmount an existing mount point
function unmount_point {
    local mount_point=$1
    if mountpoint -q "$mount_point"; then
        log "$mount_point is already mounted. Unmounting..."
        sudo umount "$mount_point" || error_exit "Error unmounting $mount_point."
    else
        log "$mount_point is not mounted."
    fi
}

# Function to handle rsync operation with optional quiet mode
function run_rsync {
    local src=$1
    local dest=$2
    local rsync_cmd="rsync -avh --progress $src $dest"

    if [ "$QUIET_MODE" = true ]; then
        rsync_cmd="rsync -avh -q $src $dest"
    fi

    $rsync_cmd || error_exit "Error copying data with rsync."
}

# Main function
function main {
    # Parse command-line options
    while getopts ":fqh" opt; do
        case $opt in
            f)
                SKIP_INTERACTIVE=true
                ;;
            q)
                QUIET_MODE=true
                ;;
            h)
                usage
                ;;
            \?)
                echo "Invalid option: -$OPTARG" >&2
                usage
                ;;
        esac
    done

    # If there's a positional argument after options (the config file), set it
    shift $((OPTIND-1))  # Remove parsed options
    if [ $# -gt 0 ]; then
        ENV_FILE="$1"
    fi

    # Check if the .env file exists
    if [ ! -f "$ENV_FILE" ]; then
        if [ "$SKIP_INTERACTIVE" = true ]; then
            error_exit "Configuration file $ENV_FILE not found and -f flag was provided. Exiting..."
        else
            log "Warning: Configuration file $ENV_FILE not found. You will be prompted to enter required variables."
        fi
    else
        # Load environment variables from the .env file
        set -a  # Automatically export all variables
        source "$ENV_FILE"
        set +a  # Stop automatically exporting variables
    fi

    # Get the required environment variables interactively, unless -f is set
    confirm_or_modify "NAS_SERVER" "${NAS_SERVER:-}"
    confirm_or_modify "MOUNT_POINT" "${MOUNT_POINT:-}"
    confirm_or_modify "NAS_TARGET_DIR" "${NAS_TARGET_DIR:-}"
    confirm_or_modify "LOCAL_HOME" "${LOCAL_HOME:-}"
    confirm_or_modify "USERNAME" "${USERNAME:-}"

    # Password handling
    if [ -z "$PASSWORD" ]; then
        if [ "$SKIP_INTERACTIVE" = true ]; then
            error_exit "Password is not set and -f flag was provided. Exiting..."
        else
            read -s -p "Please enter your NAS password: " PASSWORD
            echo
        fi
    else
        confirm_or_modify "PASSWORD" "$PASSWORD"
    fi

    # Check if all required variables are set
    if [ -z "$NAS_SERVER" ] || [ -z "$MOUNT_POINT" ] || [ -z "$NAS_TARGET_DIR" ] || [ -z "$LOCAL_HOME" ] || [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
        error_exit "One or more required environment variables are not set. Exiting..."
    fi

    # Unmount the mount point if it already exists
    unmount_point "$MOUNT_POINT"

    # Create the temporary mount directory if it does not exist
    if [ ! -d "$MOUNT_POINT" ]; then
        sudo mkdir -p "$MOUNT_POINT" || error_exit "Error creating mount point."
    fi

    log "Mounting NAS at $MOUNT_POINT..."
    sudo mount -t cifs -o username="$USERNAME",password="$PASSWORD" "$NAS_SERVER" "$MOUNT_POINT" || error_exit "Error mounting NAS."

    log "Copying data with rsync..."
    run_rsync "$LOCAL_HOME" "$MOUNT_POINT/$NAS_TARGET_DIR/"

    log "Unmounting $MOUNT_POINT..."
    sudo umount "$MOUNT_POINT" || error_exit "Error unmounting NAS."

    log "Deleting the temporary mount point $MOUNT_POINT..."
    sudo rmdir "$MOUNT_POINT" || error_exit "Error deleting temporary mount point."

    log "Backup completed successfully."
}

# Call main function
main "$@"
