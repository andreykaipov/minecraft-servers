#!/bin/sh
# shellcheck disable=SC2155

log() { printf '\033[1;33m%s\033[0m\n' "$*" >&2; }
get() { op read "op://github/$repo/$1"; }

main() {
        root=$(git rev-parse --show-toplevel)
        repo=$(basename "$root")
        log "Setting up $repo"

        : "${OP_SERVICE_ACCOUNT_TOKEN?needs to be set for op CLI}"
        op user get --me

        cmd=$1
        shift
        case "$cmd" in
                tofu) tofu "$@" ;;
                *) log "Unknown command: $cmd" ;;
        esac
}

tofu() {
        # parse -chdir flag out
        chdir_val=$(echo "$@" | grep -Po -- '-chdir=\K[^ ]+')
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
                        address="https://tf.kaipov.com/$repo/$chdir_val"
                        {
                                printf 'address="%s"\n' "$address"
                                printf 'lock_address="%s"\n' "$address"
                                printf 'unlock_address="%s"\n' "$address"
                                printf 'username="%s"\n' "$(get tf_backend_username)"
                                printf 'password="%s"\n' "$(get tf_backend_password)"
                        } >"$chdir_val/backend.conf"
                        set -x
                        command tofu -chdir="$chdir_val" init -backend-config=backend.conf "$@"
                        ;;
                *)
                        command tofu -chdir="$chdir_val" "$cmd" "$@"
                        ;;
        esac
}

set -eu
main "$@"
