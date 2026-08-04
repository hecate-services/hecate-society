#!/usr/bin/env bash
# Do the boundary guards actually go red?
#
# THIS EXISTS SO A GREEN SUITE MEANS SOMETHING. Every guard here compares one side
# of a boundary against another, and a guard that cannot fail is decoration that
# reads as protection. The predecessor lost two of three fleet nodes to a missing
# `evoq' block that every test on either side of it passed, and three commits to a
# runtime pin that two files agreed on and the developer did not.
#
# Breaks each boundary one way at a time, runs the suite, and asserts it FAILED.
# Restores every file on every exit path including a signal.
#
#   scripts/prove_the_guards_bite.sh

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}"

GUARDED=("config/sys.config.src" ".github/workflows/lint.yml" "Containerfile")
BACKUP_DIR="$(mktemp -d)"

for file in "${GUARDED[@]}"; do
    cp "${file}" "${BACKUP_DIR}/$(basename "${file}")"
done

restore() {
    for f in "${GUARDED[@]}"; do
        cp "${BACKUP_DIR}/$(basename "${f}")" "${f}"
    done
}

trap 'restore; rm -rf "${BACKUP_DIR}"' EXIT INT TERM

FAILURES=0
CHECKS=0

expect_red() {
    local what="$1"
    CHECKS=$((CHECKS + 1))
    if rebar3 eunit >/dev/null 2>&1; then
        echo "GREEN, and it should not be: ${what}"
        FAILURES=$((FAILURES + 1))
    else
        echo "red as required: ${what}"
    fi
    restore
}

# 1. The evoq block goes missing, which is the exact shape of the fleet crash.
sed -i 's/{evoq, \[/{evoq_disabled, [/' config/sys.config.src
expect_red "the evoq adapter block is absent"

# 2. The store id in config drifts away from the one the service opens.
sed -i 's/society_store/some_other_store/g' config/sys.config.src
expect_red "the config names a different store than store_id/0"

# 3. CI pins a different OTP release from the image.
sed -i 's/image: erlang:28/image: erlang:27/' .github/workflows/lint.yml
expect_red "CI and the image disagree about the OTP release"

# 4. The image pins a release nobody is running.
sed -i 's|FROM docker.io/erlang:28|FROM docker.io/erlang:27|' Containerfile
expect_red "the image pins a release this VM is not running"

echo
if [[ "${FAILURES}" -eq 0 ]]; then
    echo "all ${CHECKS} guarded boundaries bite"
else
    echo "${FAILURES} guard(s) cannot fail"
    exit 1
fi
