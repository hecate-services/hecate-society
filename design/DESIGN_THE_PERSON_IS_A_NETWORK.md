# The person is a network, and the network is not the beliefs

**Decision: behaviour is an evolved neural network, unbounded in size and shape.
Beliefs are data it reads and writes, never weights.**

Decided 2026-08-04.

---

## The apparent contradiction, resolved

[DESIGN_BELIEF_HAS_TWO_LEVELS.md](DESIGN_BELIEF_HAS_TWO_LEVELS.md) rejects a
neural network. This document builds on one. Read separately they contradict; they
do not.

**The rejection was about holding beliefs.** A network maps a situation onto a
response and cannot hold a proposition that can be stated, contested, taught or
believed against the evidence.

**Behaviour is exactly what a network is for.** Given everything I sense, including
my needs and what I believe, what do I do.

## The architecture

```
SENSORS                            HIDDEN              ACTUATORS
  my nine need levels              evolved,            act    choose a satisfier
  my model    (what I saw)         unbounded in        speak  emit a proposition
  my doctrine (what I was told)    size and shape      listen take one in
  what those near me profess                           move   attempt a crossing
  how well those near me fare                          (later) violence
  the island: capacity, crowding
```

The belief stores are **not weights**. They are data the network reads and writes:

- **doctrine** is written by other persons' `speak`
- **the model** is written by the world answering a prediction
- **the need levels** are written by the world answering an `act`

## The sentence this architecture rests on

> **Weights pass at birth. Beliefs pass by speech.**

Dual inheritance implemented as two structurally distinct channels in code rather
than as a metaphor. **It is the first thing in this design the predecessor could
not have expressed at all**, because it had no channel by which one creature's
learning could reach another.

## The transmission biases evolve; they are not handed over

An earlier draft gave conformity, prestige and content bias as capacities with
evolvable weight. Better: **give the sensor and the actuator and let the bias
evolve.** The network can see what those near it profess and how well they fare,
and whether it comes to copy the majority, or the successful, or neither, is then a
result rather than a setting.

This makes the first claim considerably stronger. As written, *conformist
transmission holds between-group variation above neutral* is half stipulated when
conformity is hand-coded. If conformity has to appear first, the claim becomes:
does it evolve, and does it then hold variation.

⚠ **And the risk is real.** The predecessor is a catalogue of things that could
have evolved and did not. If conformity never appears, the claim yields a null that
means nothing.

**So the first claim runs both arms, given and evolved, and reports both.** That is
not hedging. The given arm is the control that tells you whether the evolved arm's
null is about conformity or about the population it was run in, and without it the
result cannot be attributed.

## Why unbounded is a population decision and not a topology decision

⚠ **Read this before proposing anything large.** It is the most expensive lesson
the predecessor left.

`Ne` was guessed for twenty-two worlds and measured once, at **7.44** against a
census of 87.95, which put the drift floor at **6.72%** and made nearly every
mechanism ever priced there invisible.

**And the predecessor already ran the experiment that ambition suggests.** `J.1`
said brains stay small because the world asks only one question. World 23 gave them
a second requirement, and it was **refuted**: carriers ran 0 to 2% and the number
of ways of living explored *fell* from 81 to 64. `B.10`, that memory pays, was
refuted worse: memory was not unused, it made computation **less affordable to
have**.

**Richness was not the binding constraint. `Ne` was.** Nine need axes will not grow
a network on their own, and an unbounded topology is reachable only when a marginal
unit of computation buys more than the drift floor.

## What this track has that the last one structurally could not

The **cultural brain hypothesis** holds that brains expand in response to the
availability of information and the cost of getting it, and that social
transmission is far cheaper than working things out alone.

**The predecessor had no social learning at all.** A network could only ever be
built by mutation, and every neuron had to pay for itself against drift.

> **With teaching, the cost of acquiring a good policy stops being the cost of
> evolving one.**

That is a different economics of computation, and it is the honest reason to think
a large network is reachable here when it was not there.

It also vindicates the subsistence axis on evidence rather than taste: that
hypothesis says brains expand in response to information **and calories**. The
predecessor had calories and no information. This design has information and, in
carrying capacity, a thin honest version of calories. The literature says both are
needed.

## Sources

- [The Cultural Brain Hypothesis, Muthukrishna, Doebeli, Chudek and Henrich (PLOS Computational Biology, 2018)](https://journals.plos.org/ploscompbiol/article?id=10.1371%2Fjournal.pcbi.1006504)
- [The Cultural Brain Hypothesis (LSE ePrints, PDF)](https://eprints.lse.ac.uk/90223/7/Muthukrishna_The-cultural-brain-hypothesis.pdf)
- [Cultural evolutionary theory: how culture evolves and why it matters (PNAS)](https://www.pnas.org/doi/10.1073/pnas.1620732114)
- `hecate-biotope/PHYSICS_REGISTER.md`, entries `J.1` and `B.10`, and
  `hecate-biotope/WHY_THIS_TRACK_CLOSED.md`
