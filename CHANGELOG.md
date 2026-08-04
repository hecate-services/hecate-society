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
