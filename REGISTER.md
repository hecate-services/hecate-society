# The register

**This exists so a finding, or a mistake, is written down once and not paid for
twice.**

It continues `hecate-biotope/PHYSICS_REGISTER.md` rather than starting again.
`G.10` and `I.21` and the rest are cross-referenced from everywhere, and the one
asset worth carrying whole is the one a renumbering would break. The break is
marked here, not hidden.

---

## What carried, and what closed with the track

| series | what it is about | status |
|---|---|---|
| **`I`** | **what the instruments can be trusted to say** | **CARRIED, continues at `I.22`** |
| **`G`** | **whether the world can still change** | **CARRIED, continues at `G.11`** |
| `A` to `E` | where energy enters, what it costs to hold, to act, to transfer, where it goes | closed with the energy economy |
| `F` | perception | closed. Sensors become communication here, which is a different question and not a continuation of this one |
| `H` | what a creature can know and can do | closed |
| `J` | what a creature needs besides energy | closed |
| `R` | replication | closed |

The closed series are not deleted and not wrong. They live in the predecessor's
register, they were measured, and several of them are the reason this track
exists at all. They are closed because they are about an energy economy that this
track does not have.

**New series open here**, and the letters continue rather than reusing the closed
ones, so that a reference is never ambiguous about which track it belongs to:

| series | what it is about |
|---|---|
| `K` | what a belief is, and what holding one costs |
| `L` | how a belief moves between agents |
| `M` | what a boundary does |

## The one finding carried forward whole

**`Ne` was 7.44 against a census of 87.95, so the drift floor was 6.72%, and
nearly every mechanism ever priced against it was cheaper than that.** A mouth
0.24%, an act 1.34%, silencing 10.6% and marginal. Four hypotheses were refuted
on their own pre-registered criteria, and every one was measured at a population
where nothing of their size could have been seen.

⚠ **Cultural populations are small too, and cultural drift is a real named
phenomenon rather than a metaphor.** CHARTER.md makes the floor a live published
instrument for that reason, and makes a run below it declare itself INVALID
rather than produce a null that then gets interpreted.

---

## I. What the instruments can be trusted to say

Entries `I.1` to `I.21` are in the predecessor's register. They are about how the
work went wrong rather than about any world, and they are the expensive part.

### `I.22` A build that stops at the first failure reports a LOWER BOUND on the blockers, not the count

2026-08-04. This repository's OTP release was chosen by measurement rather than
taste, because a new repository is the one moment when changing release is free:
there are no recorded results for it to invalidate, and the cost grows with every
result after today.

OTP 29 was tried first. `reckon_gater_repl.erl` failed to compile, because 29
deprecates the old-style `catch Expr' and that module uses it five times on a
library built with warnings as errors.

**The obvious conclusion was that one short fix in a library we own stood between
this project and OTP 29. That conclusion was wrong, and it was wrong in the
direction that costs money.** rebar3 stops at the first failing application, so
the result says nothing at all about the twelve applications behind it.
Suppressing the deprecation in a throwaway build directory and letting the
compiler walk past it produced the real answer immediately:

| | | |
|---|---|---|
| `reckon_gater_repl.erl` | 5 sites | ours, a short fix |
| `khepri_import_export.erl` | 2 sites | **RabbitMQ's, needs an upstream release** |

So OTP 29 is not a decision this project can take on its own, and it is not
close. Reporting the first failure as the blocker would have turned "wait for
upstream" into "half a day", and the estimate would have been defended with
evidence.

**The rule: a compiler that halts on the first error is an instrument with a
floor. Read its output as "at least this", never as "this".** The same shape
applies to any pipeline that short-circuits, which is most of them.

### `I.23` A guard that has never been seen to fail is not known to be a guard

2026-08-04. Two boundary guards ship in this repository from the first commit:
one asserts the `evoq` block is present in `sys.config.src` wherever a store is
opened, the other asserts the store id in that config is the one `store_id/0`
actually returns. Both exist because the predecessor's fleet crash-looped on two
of three nodes for want of the first, and every test on either side of that
boundary passed throughout.

A guard of this kind is a claim about a file, and a claim about a file is easy to
write in a way that can never be false. So `scripts/prove_the_guards_bite.sh`
breaks each boundary one way at a time, runs the suite, and asserts it went RED.
It restores the file on every exit path including a signal.

**The rule: a green suite means something only if you have watched it go red for
the reason you think it is watching.** Cheap to check on the day the guard is
written, and impossible to check convincingly six months later.

---

## G. Whether the world can still change

Entries `G.1` to `G.10` are in the predecessor's register. `G.6` in particular,
that a world was not a pure function of its seed for seventeen worlds because two
functions walked maps in unpromised order, is the reason both repositories pin
their OTP release in the image and in CI and test that the two agree.

*(No entries yet in this track.)*

---

## K. What a belief is, and what holding one costs

*(No entries yet. CHARTER.md rules that beliefs are two levels, a `model` written
only by observation and a `doctrine` written only by other agents, and that their
disagreement is the subject. Nothing is built.)*

## L. How a belief moves between agents

*(No entries yet. Conformist, prestige and content bias are given as capacities
with evolvable weight rather than as settings.)*

## M. What a boundary does

*(No entries yet. `border.erl` is ported and its two rules, `closed` and `full`,
both read the island and ignore the traveller. The day a rule reads the traveller
this system has a politics, and that is the first entry this series will get.)*
