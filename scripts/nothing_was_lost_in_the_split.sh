#!/usr/bin/env bash
# Did the charter split drop anything?
#
# THIS EXISTS BECAUSE A REORGANISATION IS THE EASIEST WAY TO DELETE SOMETHING
# WITHOUT NOTICING. CHARTER.md went from 622 lines to a front door and six
# documents under design/. A diff of that is unreadable, so it cannot be reviewed
# by eye, and "it looks fine" is how a paragraph goes missing for a year.
#
# So: a list of the load-bearing phrases from the pre-split charter, each of which
# must still exist SOMEWHERE in the repository's markdown. It does not check that
# each landed in the RIGHT place, only that none vanished. That is the failure
# worth automating; the rest is review.
#
#   scripts/nothing_was_lost_in_the_split.sh

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}"

MISSING=0

# ⚠ THE FIRST VERSION OF THIS SCRIPT REPORTED FIVE FALSE LOSSES, and every one of
# them was still in the repository. A plain `grep -F` over markdown cannot match a
# phrase that has been line-wrapped by the editor, and cannot match one carrying
# emphasis: *fell* from 81 to 64, or an **operator**.
#
# A check that cries wolf is a check people stop reading, which is worse than no
# check at all. So the corpus is flattened first: every markdown file
# concatenated, emphasis and code markers removed, all whitespace collapsed to
# single spaces. The needles get the same treatment, and then a literal match
# means what it says.
CORPUS="$(find . -name '*.md' -not -path './_build/*' -print0 \
          | xargs -0 cat \
          | tr -d '*_`' \
          | tr -s '[:space:]' ' ')"

must_survive() {
    local phrase flattened
    phrase="$1"
    flattened="$(printf '%s' "${phrase}" | tr -d '*_`' | tr -s '[:space:]' ' ')"
    if printf '%s' "${CORPUS}" | grep -qF "${flattened}"; then
        printf '  ok   %s\n' "${phrase}"
    else
        printf '  LOST %s\n' "${phrase}"
        MISSING=$((MISSING + 1))
    fi
}

echo "load-bearing phrases from the pre-split charter:"

# The contribution and the definition
must_survive "Axelrod's agents sit on a lattice"
must_survive "second inheritance system"
must_survive "A run in which"

# The two schools
must_survive "infrastructure determines structure"
must_survive "formalism against substantivism"
must_survive "formalist at the person and substantivist at the island"

# Belief
must_survive "Doctrine is a set, not a slot"
must_survive "checkable against the world"
must_survive "internalisation continuum"

# Needs
must_survive "subsistence, protection, affection, understanding, participation"
must_survive "A culture is not a weighting over the axes"
must_survive "No need may have code of its own"
must_survive "pseudo-satisfiers"
must_survive "violators"
must_survive "incommensurable"

# Economy
must_survive "attends to only so many others per tick"
must_survive "number of learners to whom it transmits"
must_survive "Carrying capacity is one number"
must_survive "reciprocity, redistribution, and market exchange"

# The network
must_survive "Weights pass at birth"
must_survive "unbounded in"
must_survive "cultural brain hypothesis"
must_survive "both arms, given and evolved"

# Life, death, violence
must_survive "presence with a natural end"
must_survive "Imposition is what conformity and prestige look like"
must_survive "A raid is migration that does not ask"
must_survive "lifespan turned out"

# The rules and the boundary
must_survive "declares itself invalid"
must_survive "A guard compares two sides of a boundary"
must_survive "Every register entry carries an ELI5"
must_survive "no number in"
must_survive "an operator"
must_survive "our simulation shows open borders cause"

# Ne
must_survive "7.44"
must_survive "6.72%"
must_survive "fell from 81 to 64"

echo
if [[ "${MISSING}" -eq 0 ]]; then
    echo "nothing was lost"
else
    echo "${MISSING} phrase(s) went missing in the split"
    exit 1
fi
