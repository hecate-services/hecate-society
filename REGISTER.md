# The register

**This exists so a finding, or a mistake, is written down once and not paid for
twice.**

It continues `hecate-biotope/PHYSICS_REGISTER.md` rather than starting again.
`G.10` and `I.21` and the rest are cross-referenced from everywhere, and the one
asset worth carrying whole is the one a renumbering would break. The break is
marked here, not hidden.

---

## ⚠ EVERY ENTRY CARRIES AN ELI5 SECTION. NO EXCEPTIONS.

CHARTER.md rule 10, from 2026-08-04. Every entry below ends with **ELI5**: the
finding in plain language, for somebody who knows none of this.

**Written in the same commit as the entry, by whoever wrote the entry.** The
sibling practice on `beam-campus-net` keeps its plain-language layer in a separate
repository, written later, and that project's own standing warning is that a
published post still asserting a later-refuted finding is the worst failure it can
have. **An explanation written elsewhere and afterwards is a translation, and
translations drift.** One written in the same commit cannot.

And it is a comprehension test before it is outreach. **If the finding cannot be
explained without the vocabulary, it is not yet understood.** The most expensive
entries in the predecessor's register are the ones where somebody believed they
understood a thing they had only named.

Rules for writing one: no jargon, and no term defined only elsewhere in this
repository. Say what happened, what it cost, and what to do differently. If it
needs a picture, use an everyday one. Length is whatever it takes, which is
usually a short paragraph.

The two entries below were written before the rule and have been brought up to
it, because a rule with no worked example is a rule nobody follows.

## When this file splits

**One file until it passes about 800 lines, then one file per series under
`register/`, with this page kept as the index.**

The predecessor's register reached 108KB in a single file, which is past the point
where it can be read or processed in one piece, and it was never split because by
then everything cross-referenced everything. **The threshold is written down now so
the split happens on a number rather than on somebody's patience.**

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
| `L` | how a belief moves between persons |
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

**ELI5.** Imagine testing a long string of fairy lights with a tester that stops
at the first dead bulb. You find one, and it is a bulb you happen to have a spare
for, so you think you are five minutes from finished. But the tester never got
past that bulb, so it never looked at the other twelve.

We wanted to move to a newer version of the language we build in. The build
stopped at the first library that would not compile. That library is one of ours
and the fix was small, so it looked like we were half a day away from having it.
Then we told the build to skip past that one and look further, and a second
library failed too, and that one belongs to somebody else, so we cannot fix it and
have to wait for them.

Half a day turned into wait-for-someone-else, and the only thing that changed was
looking past the first problem. **When a checker stops at the first fault, what it
tells you is "at least this much is broken", never "this much".**

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

**ELI5.** A smoke alarm you have never tested is not a smoke alarm. It is a
plastic box on the ceiling that you believe in.

We have two checks whose whole job is to catch one particular mistake, a mistake
that once knocked over three of our four machines and kept them down. The trouble
is that a check which reads a file can very easily be written so that it passes no
matter what the file says, and nothing would ever tell you. It would sit there
looking reassuring for years.

So we wrote a small script that goes and breaks the thing on purpose, one way at a
time, runs the checks, and makes sure they fail. Then it puts everything back. Both
of them failed when they should have. **Now we know they are alarms rather than
boxes**, and we knew it on the day we put them up, which is the only day it is
cheap to find out.

### `I.24` An invariant that holds only in expectation is not an invariant

2026-08-04. The neutral-copying model has no innovation at all, so a label that is
lost is lost for ever. A test therefore asserted that **diversity only ever
falls**, and it failed on the first run, and the first suspicion was that the
model was broken.

The test was wrong. What can never rise is the **number of distinct labels**.
Diversity is `1 - sum(p^2)`, which measures how EVEN the frequencies are, and
evenness fluctuates in both directions in a finite population. Sixty people
holding 59 and 1 have less diversity than the same sixty holding 58 and 2, so a
rare label drifting upward raises diversity while nothing has been invented and
nothing has been recovered.

**Drift lowers diversity in expectation, not in realisation.** The test now
asserts the thing that is actually invariant, and a separate one asserts the
long-run statement that the estimator really rests on.

**The rule: before asserting a quantity is monotonic, ask whether it is monotonic
in every run or only on average.** The second kind produces a red test that looks
exactly like a broken model, and the cost is paid in doubting correct code.

**ELI5.** If you have a jar of red and blue marbles and you keep replacing marbles
with copies of other marbles in the jar, eventually the jar ends up all one
colour. That is certain. What is not certain is that it gets closer to one colour
every single time you look. If there is one blue marble left and it happens to get
copied, there are briefly two, and the jar is more mixed than it was a moment ago.
It is still heading for all-one-colour and it did not go backwards in any real
sense, it just wobbled. We wrote a test saying "the mixture must go down every
time we look", and the jar was behaving perfectly.

### `I.25` A fit whose window depends on where the data happens to hit zero is measuring the window

2026-08-04, found immediately after the first run of the floor measurement.

The effective size is read off how fast diversity decays, by fitting a straight
line through its logarithm. Points where diversity is exactly zero cannot be
logged and were dropped. Everything else was kept.

**The symptom: a census of 400 reported an effective size of 243 while a census of
100 reported 101.** Nothing about the model differed between them.

What differed was the tail. The small run fixed on one label early, so its late
samples were exactly zero and were already excluded by the filter. The large run's
tail was small but non-zero, so dozens of points where a couple of lineages were
scrapping over the last few percent went into the fit weighted exactly as heavily
as the clean early decay, and dragged the slope.

**So the estimator's answer depended on how much of its tail happened to land
exactly on zero, which is a property of the run length and the population, not of
the population's effective size.** The fit now runs over a stated window, from the
start down to a twentieth of the starting diversity.

**The rule: when a fit excludes points by a rule like "not zero", check what the
surviving points near that boundary are made of.** Excluding the impossible is not
the same as excluding the uninformative, and the difference is invisible until two
runs that should agree do not.

**ELI5.** Imagine timing how fast a bath empties by watching the water level. At
the start the level drops steadily and you can measure it well. At the very end
there is a puddle sloshing around the plughole, and the level jumps about for
reasons that have nothing to do with how fast the bath drains.

We measured the whole thing, puddle included, and gave the puddle just as much say
as the steady part. A big bath has a longer puddle phase than a small one, so the
two baths gave different answers for the same plughole. Now we stop measuring once
most of the water is gone, and both baths agree.

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
only by observation and a `doctrine` written only by other persons, and that their
disagreement is the subject. Nothing is built.)*

## L. How a belief moves between persons

*(No entries yet. Conformist, prestige and content bias are given as capacities
with evolvable weight rather than as settings.)*

## M. What a boundary does

*(No entries yet. `border.erl` is ported and its two rules, `closed` and `full`,
both read the island and ignore the traveller. The day a rule reads the traveller
this system has a politics, and that is the first entry this series will get.)*
