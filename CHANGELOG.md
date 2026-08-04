# Changelog

All notable changes to this project are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and
this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **CHARTER.md**, opening the track. The end goal in one line, the two-level
  belief store ruled on, seven instruments named before any mechanism, the order
  of work classified into BUILD and CLAIM, and the ethical boundary set on day
  one rather than added after the first suggestive picture.
- The service scaffold: boots on `hecate_om`, joins the mesh, answers `/health`
  on 8484, opens a reckon-db store for the notebook. Holds no island, publishes
  nothing, announces no capability.
- CI on OTP 28 for lint and unit tests, and an OCI image pushed to ghcr.io on
  every push to `main`.

### Changed

- **CHARTER.md, first revision.** Both schools taken at two scales rather than one
  chosen, with the fork named so build order cannot settle it silently. Max-Neef's
  nine needs adopted whole, with a rule that no need may have code of its own so
  that nine axes stay data rather than nine subsystems. **A culture is a set of
  satisfiers**, replacing an earlier and weaker "a weighting over axes". Max-Neef's
  violators and pseudo-satisfiers adopted as the measurable form of a culture being
  bad for its carriers. Incommensurability made explicit, so nothing is ever summed
  into a scalar welfare. Attention named as the scarce contested quantity, cultural
  fitness defined as the count of learners, and welfare held separate from both.
  Carrying capacity adopted as the whole material base, reusing `max_persons`.
  **The person is a network** with unbounded hidden layers and beliefs as data
  rather than weights: weights pass at birth, beliefs pass by speech. Transmission
  biases moved from given to evolved, with the first claim running both arms. Life
  defined as presence with a natural end. Violence placed between islands first,
  and conquest shown to need no mechanism of its own. `Ne` promoted to its own
  section as the binding constraint on ambition. Sources listed, and
  self-determination theory recorded as considered and not adopted, with why.
- **Rule 10: every register entry carries an ELI5 section**, written in the same
  commit by whoever wrote the entry. `REGISTER.md` states the format and the two
  existing entries were brought up to it, because a rule with no worked example is
  a rule nobody follows.

### Decided

- **OTP 28 rather than 29**, on measurement. The dependency tree fails to compile
  on 29: `reckon_gater_repl.erl` and `khepri_import_export.erl` both use the
  old-style `catch` that 29 deprecates, on libraries built with warnings as
  errors. The first is ours, the second is upstream. See the `Containerfile`.
- **One member of a population is a `person`, plural `persons`**, not an agent, a
  mind or a human. The predecessor's word was `creature` and it went with the
  biology.

  It was `mind` for about an hour, chosen to keep the public artifact safe, and
  changed once it was settled that **persons will eventually kill each other
  here**. Between-group lethal conflict is a load-bearing mechanism in cultural
  group selection rather than an ugly extra, and a model that kills things should
  use the noun where killing sounds like killing. The screenshot risk is real and
  is accepted rather than dodged: it is answered in `CHARTER.md` and in how every
  claim is worded, not by a softer noun.

  An island holds **a people**, always with the article. A human being who runs a
  node is an **operator** or an **owner**. Two references to Axelrod's agents
  stay, because they describe the existing literature rather than anything built
  here.
- **The register keeps its numbering** from `hecate-biotope`. `G.10` and `I.21`
  and the rest are cross-referenced from everywhere, and renumbering would break
  the one asset worth carrying whole.
- **Code is copied from the predecessor, not extracted into a library.** Two
  consumers is a copy, and that track is closed so divergence costs nothing.
