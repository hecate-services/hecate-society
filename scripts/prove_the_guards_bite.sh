#!/usr/bin/env bash
# Do the two boundary guards actually go red?
#
# THIS EXISTS SO A GREEN SUITE MEANS SOMETHING. Both guards compare the Erlang
# side of a boundary against the config side, and a guard that cannot fail is
# decoration that reads as protection. The predecessor lost two of three fleet
# nodes to a missing `evoq' block that every test on either side of it passed.
#
# Breaks `config/sys.config.src' one way at a time, runs the suite, and asserts
# it FAILED. Restores the file on every exit path including a signal.
#
#   scripts/prove_the_guards_bite.sh

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="${ROOT}/config/sys.config.src"
BACKUP="$(mktemp)"

cp "${CONFIG}" "${BACKUP}"
trap 'cp "${BACKUP}" "${CONFIG}"; rm -f "${BACKUP}"' EXIT INT TERM

FAILURES=0

expect_red() {
    local what="$1"
    if (cd "${ROOT}" && rebar3 eunit >/dev/null 2>&1); then
        echo "GREEN, and it should not be: ${what}"
        FAILURES=$((FAILURES + 1))
    else
        echo "red as required: ${what}"
    fi
    cp "${BACKUP}" "${CONFIG}"
}

# 1. The evoq block goes missing, which is the exact shape of the fleet crash.
sed -i 's/{evoq, \[/{evoq_disabled, [/' "${CONFIG}"
expect_red "the evoq adapter block is absent"

# 2. The store id in config drifts away from the one the service opens.
sed -i 's/society_store/some_other_store/g' "${CONFIG}"
expect_red "the config names a different store than store_id/0"

echo
if [[ "${FAILURES}" -eq 0 ]]; then
    echo "both guards bite"
else
    echo "${FAILURES} guard(s) cannot fail"
    exit 1
fi
