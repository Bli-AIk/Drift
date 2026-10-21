#!/usr/bin/env bash
# A `shell:` for workflow steps that must run inside the long-lived container named by
# $CI_CONTAINER (see the arch job in .github/workflows/package.yml): the step script {0} is
# executed there with the step's environment and working directory carried across, which
# `docker exec` does not do on its own.
set -euo pipefail

script="${1:?usage: docker-exec-shell.sh <step-script>}"

# Host-only variables that would be wrong inside the container.
skip='^(PATH|HOME|USER|LOGNAME|SHELL|PWD|OLDPWD|SHLVL|_|TERM|HOSTNAME|BASH.*|CI_CONTAINER)$'
envargs=()
while IFS= read -r name; do
    [[ "$name" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || continue
    [[ "$name" =~ $skip ]] && continue
    envargs+=(-e "$name")
done < <(compgen -e)

exec docker exec "${envargs[@]}" -w "$PWD" "${CI_CONTAINER:?}" bash -e "$script"
