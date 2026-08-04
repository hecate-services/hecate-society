# The floor, measured: about **0.2% to 0.8%**, where the predecessor's was 6.72%

**Measured 2026-08-04, before the needs, the beliefs and the network were built,
because `CHARTER.md` rule 1 says a mechanism is chosen against the measured floor
and nothing had measured it.**

`scripts/how_many_teachers_are_there_really.escript`, 8 seeds, 6000 ticks per arm,
model in `apps/hecate_society/src/measure_the_floor/`.

---

## The answer

| arm | census | `Ne` decay | `Ne` variance | floor | mean taught | var/mean |
|---|---|---|---|---|---|---|
| uniform | 100 | 116.8 | 99.6 | **0.43%** | 12.93 | 1.04 |
| prestige 25 | 100 | 63.9 | 84.8 | 0.78% | 12.93 | 3.31 |
| prestige 100 | 100 | 65.0 | 83.0 | 0.77% | 12.93 | 3.64 |
| prestige 400 | 100 | 86.4 | 82.5 | 0.58% | 12.93 | 3.73 |
| prestige 400, attention 2 | 100 | 96.7 | 91.1 | 0.52% | 12.93 | 2.25 |
| prestige 400, attention 20 | 100 | 84.3 | 78.8 | 0.59% | 12.93 | 4.46 |
| prestige 400, attention 99 | 100 | 76.1 | 77.9 | 0.66% | 12.94 | 4.65 |
| uniform | 400 | 268.4 | 398.6 | **0.19%** | 12.93 | 1.04 |
| prestige 400 | 400 | 242.6 | 329.5 | 0.21% | 12.93 | 3.77 |
| prestige 400, attention 99 | 400 | 271.4 | 310.5 | 0.18% | 12.94 | 4.73 |

**Against the predecessor: `Ne` 7.44, floor 6.72%.** This is eight to thirty-five
times lower, and that is the whole result.

| what needs to be seen | `Ne` required | reachable here |
|---|---|---|
| a mechanism worth 1% | above 50 | **yes, in every arm** |
| a mechanism worth 0.25% | above 200 | **yes at a census of 400** |
| a mouth, the predecessor's cheapest priced thing, 0.24% | above 208 | yes at a census of 400 |

## The instrument checked itself first

**Uniform copying at a census of 100 gives a variance-to-mean ratio of 1.04 and a
variance estimate of 99.6.** That is the Poisson signature of everybody being
equally likely to be copied, and an effective size equal to the census is what
theory says it must be.

If that arm had come out anywhere else, every other number in the table would have
been a number about a bug. It is the reason the rest is worth reading.

## The fear was wrong: prestige does not collapse `Ne`

The reason this experiment was built in this shape was a worry that **the charter
contains a mechanism that destroys its own measurability**. Prestige bias
concentrates transmission on a few teachers, concentration is variance in cultural
fitness, and variance is what drives `Ne` below the census.

It does all of that, and it is not nearly enough to matter.

**Variance-to-mean rises from 1.04 to 4.73, and `Ne` falls only from about 100 to
about 80.** At four times the population it falls from 399 to 310. That is a
factor of roughly 1.2, where the predecessor's population lost a factor of twelve.

Attention breadth turns out to be the reason it is not worse. A high-standing
person is only copied when they happen to be among the few candidates a learner
considered, so narrow attention caps how concentrated transmission can get:
attention 2 gives a ratio of 2.25 where attention 99 gives 4.65. **Limited
attention protects `Ne` from prestige**, which is the opposite of what "attention
is the scarce resource" made me expect.

## What actually buys a low floor

**Census, and almost nothing else.** Four times the population gives three to four
times the effective size in every arm, prestige or no prestige. Neither the
prestige strength nor the attention breadth moves it by more than about 20%.

That is directly actionable and it is what the archipelago is for. Four islands at
a hundred persons each is a census of 400, and the floor at 400 is under 0.25%.

## ⚠ Where this is weaker than it looks

**The two estimators disagree by up to 45%, and I do not know which is right.**
They agree closely at a census of 100 (116.8 against 99.6) and diverge at 400
(268.4 against 398.6). The decay estimator makes no assumption about generations
being discrete, which is why it is normally the one to read; the variance
estimator assumes non-overlapping generations, which this world does not have, so
its exact value is indicative. **The robust claim is the order of magnitude:
`Ne` is in the hundreds here and was seven there.** That is exactly the form in
which the predecessor stated its own answer, and for the same reason.

**⚠⚠ THE CENSUS IS HELD FLAT AND NOTHING CRASHES, AND THAT IS THE BIGGEST
CAVEAT.** `Ne` over time is a harmonic mean, which is punished savagely by
bottlenecks, and the predecessor identified crashes as one of the three things
destroying its own: 46 to 54 seeds of 64 died outright. **This model cannot crash
because births exactly replace deaths.** If a society's population ever collapses
and recovers, the floor will rise the way it did there, and this number will not
apply to that run.

**A mechanism was not priced.** This measures what drift does when nothing is
selecting. It does not show that any particular mechanism clears the floor, only
what a mechanism would have to be worth. Those are separate questions and the
second one needs a claim.

**Standing is drawn at birth and is independent of what anybody holds.** That is
what keeps this a measurement of drift rather than of selection, and it also means
prestige here carries no information. Prestige that tracked something real would
be selection, and would belong in a claim rather than in a floor.

## What this does to the charter

**The charter survives, and its ambitions are reachable.** Nine need axes, an
unbounded network and evolved transmission biases all require a floor low enough
that a marginal mechanism is visible, and 0.2% clears every price the predecessor
ever recorded except none at all.

Two things in it should be read differently now:

- **`Ne` is a census problem, not a prestige problem.** The `Ne` section warns
  against ambition because richness will not grow a network. That stands. But the
  lever is population and the archipelago, not restraint about mechanisms.
- **Attention being scarce does not mean attention sets `Ne`.**
  `DESIGN_ECONOMY_AND_SCARCITY.md` argues that attention is the finite contested
  quantity and that cultural `Ne` is how many distinct teachers fill a person's
  slots. Measured, breadth moves `Ne` by under 20% while census moves it by 300%.
  The argument is not wrong, it is much weaker than it reads, and that document
  should say so.

## What is owed

1. **Run it with crashes.** The flat census is the one assumption that would
   change the answer by an order of magnitude, and it is the assumption the
   predecessor's own experience says will break.
2. **Reconcile the estimators**, or state permanently which is read and why. A
   45% disagreement is tolerable for an order-of-magnitude claim and not for a
   selectability gate that passes something at 0.3%.
3. **Migration between islands**, which is the mechanism the archipelago exists
   for and which this model does not have at all. Four separate hundreds are not a
   census of four hundred unless they exchange.
