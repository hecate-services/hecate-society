# Claims

**A claim is an assertion about the world that could be wrong. Everything else is
a build, and a build does not come here.**

Empty so far, deliberately. `CHARTER.md`'s order of work puts four BUILDs before
the first claim, and a claim registered before the machinery exists is a
pre-registration nobody could have honoured.

## A claim is a vertical slice

**One directory per claim, holding its pre-registration, its results and its
data.**

```
claims/
  CLAIM_01_conformist_transmission_holds_variation/
    PREREGISTRATION.md    written BEFORE the run, and never edited after it
    RESULTS.md            what happened, including the arms that killed everything
    data/                 whatever the run produced
```

The predecessor did not do this. It had twenty-three `PREREGISTRATION_WORLD*.md`
and twenty-three `RESULTS_WORLD*.md` flat in its root, and reading one experiment
meant finding two files among fifty that had drifted apart in wording and in
numbering. **Co-locating them is the same rule the code follows: one capability,
one directory, everything about it together.**

## What a pre-registration must contain

Carried whole from the predecessor, where the discipline refuted four of its own
hypotheses on criteria written in advance. That is the most valuable thing it
built.

- **The claim, in one sentence**, stated so it can be wrong.
- **Which of the two schools it bears on.** `DESIGN_TWO_SCHOOLS_AT_TWO_SCALES.md`
  names a live fork between material conditions and transmission dynamics, and
  build order will settle it silently unless every claim says which one it is
  testing.
- **The instrument, named**, and it must already exist and already be published.
- **The negative, stated in advance.** What result would count as refuted, written
  before the run so it cannot be reinterpreted afterwards.
- **The selectability gate.** The differential this mechanism would have to
  produce, against the *measured* drift floor, for the instrument to be able to
  see it at all. Under the floor means do not run it: raise `Ne` first.
- **What is given and what must emerge**, said plainly, per charter rule 4.
- **What will not happen**, so an absence is never read afterwards as a finding.

## What a result must contain

- **The whole sweep, including the arms that killed everything.** Never only the
  arm that worked.
- **The exercise count beside every null**, per charter rule 3. A capacity that
  was never used is not evidence of anything.
- **`Ne` as measured during the run**, and a run below the usable floor declares
  itself invalid rather than producing a null that then gets interpreted.
- **An honest verdict against the negative that was written in advance**, in those
  words, without softening.
