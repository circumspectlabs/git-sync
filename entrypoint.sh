#!/bin/bash

###
### This script just checks if it is running with root and tries to fix
### file permissions if it is. If non-root, then it just execs the command.
###
set -e

SKIP_CHOWN=${SKIP_CHOWN:-"false"}
SKIP_KEY_PERMISSIONS=${SKIP_KEY_PERMISSIONS:-"false"}

export GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

if [ "$(id -u)" = "0" ]; then
    if [ "$SKIP_CHOWN" = "false" ]; then
        chown -R -h -f 65534:65534 /.ssh /data || true
    fi

    if [ "$SKIP_KEY_PERMISSIONS" = "false" ]; then
        # seek for --ssh-key-file, then copy (cat) the file and fix permissions
        catch_next="false"
        new_args=()
        for arg in "$@"; do
            if [[ "$arg" == --ssh-key-file=* ]]; then
                ssh_key_file="${arg#*=}"
                if [ -f "$ssh_key_file" ]; then
                    cat "$ssh_key_file" > "/.ssh/ssh_key"
                    chmod 0600 "/.ssh/ssh_key"
                    chown 65534:65534 "/.ssh/ssh_key"
                    new_args+=("--ssh-key-file=/.ssh/ssh_key")
                else
                    echo "WARNING: SSH key file '$ssh_key_file' does not exist"
                    new_args+=("$arg")
                fi
                continue
            fi
            if [[ "$arg" == --ssh-key-file ]]; then
                new_args+=("$arg")
                catch_next="true"
                continue
            fi
            if [[ "$catch_next" == "true" ]]; then
                catch_next="false"
                ssh_key_file="$arg"
                if [ -f "$ssh_key_file" ]; then
                    cat "$ssh_key_file" > "/.ssh/ssh_key"
                    chmod 0600 "/.ssh/ssh_key"
                    chown 65534:65534 "/.ssh/ssh_key"
                    new_args+=("/.ssh/ssh_key")
                else
                    echo "WARNING: SSH key file '$ssh_key_file' does not exist"
                    new_args+=("$arg")
                fi
                continue
            fi
            new_args+=("$arg")
        done
    else
        new_args=("$@")
    fi

    exec gosu 65534:65534 "${new_args[@]}"
else
    exec "$@"
fi
