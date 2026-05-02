# git-sync

Just a docker image with git-sync, as minimal as possible. Just with
minimal alpine and a script to fix general permission issues without
sacrificing security. othing fancy.

## Features

- `ca-certificates` to support https repos
- `git-lfs`
- `curl` and `bash` for git hooks and extras

## Usage

```bash
# show help
docker run -i \
    ghcr.io/circumspectlabs/git-sync:latest \
    --help

# using ssh deploy key
chmod 0600 $(pwd)/deploy-key
chown 65534:65534 $(pwd)/deploy-key
docker run -d \
        -v $(pwd)/deploy-key:/ssh/deploy-key:ro \
        -v $(pwd)/data:/data \
    ghcr.io/circumspectlabs/git-sync:latest \
        --ssh-key-file /ssh/deploy-key \
        --repo git@github.com:circumspectlabs/git-sync.git \
        --ref master \
        --root /data

# using pat or password
docker run -d \
        -v $(pwd)/data:/data \
        -e "GITSYNC_PASSWORD=password" \
    ghcr.io/circumspectlabs/git-sync:latest \
        --repo https://github.com/circumspectlabs/git-sync \
        --root /data

# with permission fixes routines (ssh key and data folder), but
# requires starting from root and linux capabilities (available
# by default): cap_chown, cap_fowner, cap_setgid, cap_setuid.
docker run -d \
        -v ~/.ssh/deploy-key:/ssh-original/deploy-key:ro \
        -v $(pwd)/data:/data \
        -u 0:0 \
    ghcr.io/circumspectlabs/git-sync:latest \
        --ssh-key-file /ssh-original/deploy-key \
        --repo git@github.com:circumspectlabs/git-sync.git \
        --root /data

# some useful settings, see --help
docker run -d \
        -v ~/.ssh/deploy-key:/ssh-original/deploy-key:ro \
        -v $(pwd)/data:/data \
        -u 0:0 \
    ghcr.io/circumspectlabs/git-sync:latest \
        --sync-on-signal SIGHUP \
        --period 1m \
        --git-gc auto \
        --stale-worktree-timeout 10m \
        --ref main \
        --password-file "/mnt/my-password-or-token-file" \
        --submodules off \
        --username non-default-git-user \
        --one-time \
        --link git-sync
```
