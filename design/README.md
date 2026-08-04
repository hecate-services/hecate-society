# Design

**One document per topic, each carrying its decision, the reasoning that produced
it, and the sources it rests on.**

`CHARTER.md` in the root is the front door: the end goal, the contribution, the
rules, the instruments, the ethical boundary and the order of work. It states what
this track is committed to. **These documents say why**, and they are where a
commitment gets relitigated if new information arrives.

## Why the split is by topic and never by kind

A `commitments/` directory and a `reasoning/` directory would be two technical
layers, neither of which is a subject. This codebase forbids exactly that shape in
code: `border.erl` carries sixty lines of why above forty lines of what, because a
decision separated from its reason gets undone by whoever reads only one of them.

The same rule applies to prose. **A document is a vertical slice: one topic, its
decision, its reasoning and its evidence, together.**

So sources live inside the document that uses them. There is deliberately no
central bibliography, because a second list of the same things is a second thing
that drifts out of agreement with the first, and this project has paid for that
already.

## The documents

| document | what it decides |
|---|---|
| [DESIGN_TWO_SCHOOLS_AT_TWO_SCALES.md](DESIGN_TWO_SCHOOLS_AT_TWO_SCALES.md) | that material conditions are the selective environment and transmission is the search process, and that the fork between them is named rather than settled |
| [DESIGN_BELIEF_HAS_TWO_LEVELS.md](DESIGN_BELIEF_HAS_TWO_LEVELS.md) | the `model` and the `doctrine`, who may write to each, and why their disagreement is the subject |
| [DESIGN_NEEDS_AND_SATISFIERS.md](DESIGN_NEEDS_AND_SATISFIERS.md) | the nine axes, that a culture is a set of satisfiers, incommensurability, and how a culture can be measurably bad for its own persons |
| [DESIGN_ECONOMY_AND_SCARCITY.md](DESIGN_ECONOMY_AND_SCARCITY.md) | that attention is what is scarce, that fitness is the count of learners, and that welfare is a third thing held apart from both |
| [DESIGN_THE_PERSON_IS_A_NETWORK.md](DESIGN_THE_PERSON_IS_A_NETWORK.md) | sensors, unbounded hidden layers, actuators, and that beliefs are data rather than weights |
| [DESIGN_LIFE_DEATH_AND_VIOLENCE.md](DESIGN_LIFE_DEATH_AND_VIOLENCE.md) | what a life is, why natural mortality is load-bearing, and why conquest needs no mechanism of its own |
| [RESEARCH_THE_MEASURED_FLOOR.md](RESEARCH_THE_MEASURED_FLOOR.md) | **the drift floor, measured rather than assumed.** Every selectability gate is read against this number |

## What goes here, and what does not

**Here:** a decision that shapes the model, with its reasoning. An exploration
that has not yet become a decision, named `EXPLORATION_*.md`. Research that
informs several decisions, named `RESEARCH_*.md`.

**Not here:** a claim about the world. That is a pre-registration and it lives in
`claims/`. A finding or a mistake, which is an entry in `REGISTER.md`. How the
service is built, run or deployed, which is `README.md`.
