#!/bin/sh
# shellcheck disable=SC2155

log() { printf '\033[1;33m%s\033[0m\n' "$*" >&2; }
get() { op read "op://$repo/$1"; }

main() {
        root=$(git rev-parse --show-toplevel)
        repo=$(basename "$root")
        log "Setting up $repo"

        : "${OP_SERVICE_ACCOUNT_TOKEN?needs to be set for op CLI}"
        op user get --me >&2

        cmd=$1
        shift
        case "$cmd" in
                tofu) tofu "$@" ;;
                *) log "Unknown command: $cmd" ;;
        esac
}

tofu() {
        # parse -chdir flag out from args
        chdir_val=$(echo "$@" | grep -Po -- '-chdir=\K[^ ]+')
        chdir_val_slug=$(printf '%s' "$chdir_val" | tr -c 'a-zA-Z0-9-_.' _)
        for arg; do
                shift
                if echo "$arg" | grep -qE -- '-chdir=[^ ]+'; then continue; fi
                set -- "$@" "$arg"
        done

        export TF_VAR_root="$root"
        export TF_VAR_repo="$repo"

        cmd=$1
        shift
        case "$cmd" in
                init)
                        address="https://tf.kaipov.com/$repo/$chdir_val_slug"
                        f="/tmp/backend.$chdir_val_slug.conf"
                        {
                                printf 'address="%s"\n' "$address"
                                printf 'lock_address="%s"\n' "$address"
                                printf 'unlock_address="%s"\n' "$address"
                                printf 'username="%s"\n' "$(get setup/tf_backend_username)"
                                printf 'password="%s"\n' "$(get setup/tf_backend_password)"
                        } >"$f"
                        set -x
                        command tofu -chdir="$chdir_val" init -backend-config="$f" "$@"
                        ;;
                *)
                        command tofu -chdir="$chdir_val" "$cmd" "$@"
                        ;;
        esac
}

set -eu
main "$@"
