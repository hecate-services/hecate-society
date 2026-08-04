# hecate-society

**This exists so that adding a machine to the mesh adds a people, and the network
between the machines is the border between their cultures.**

An island is one node's piece of the world. It holds a population of persons who
believe things, teach each other, and check what they were taught against what
they see. Islands meet by exchanging migrants over the mesh, and each island
decides for itself who may land.

Read [CHARTER.md](CHARTER.md) before the code. It says what is given and what
must emerge, names the instruments before the mechanisms, and sets the ethical
boundary.

## Status

**Scaffold.** The service boots, joins the mesh, and answers `/health` on 8484.
It holds no island, publishes nothing, and announces no capability.

That is deliberate and it is the same order the predecessor used: the release,
the image, the CI and the deployment are the tedious end and the one that is
expensive to retrofit, so it is finished first and no increment is ever blocked
waiting on plumbing.

## Where this came from

It follows an artificial-life track, `hecate-biotope`, closed after twenty-four
worlds. That track's own account of why is in its `WHY_THIS_TRACK_CLOSED.md`, and
the short version is that at an effective population of 7.44 the drift floor was
6.72% and nearly every mechanism ever priced there was cheaper than that.

**What carries over:** islands, migration, the border, island identity, the mesh
substrate, the pre-registration discipline, the physics register, the wire rules.

**What does not:** the energy economy. Food, metabolism, thirst and predation are
biology. Attention and time are the cultural analogues and they are not the same
thing.

## Build and run

```
rebar3 compile
rebar3 lint
rebar3 eunit
rebar3 as prod release
```

`scripts/health.sh [host]` asks a running island how it is, and distinguishes
unreachable from unhealthy because they send you to look in different places.

## Runtime

| variable | what it does |
|---|---|
| `HECATE_REALM` | 64-hex fleet realm tag. Required. Read as an application env, not a shell variable, and `config/sys.config.src` is the only place the two meet |
| `HECATE_HEALTH_PORT` | health listener, 8484 in the image |
| `HECATE_SOCIETY_DATA_DIR` | where the notebook and the island's identity live. **Must be a mounted volume on a node**, or the island becomes a new island at every restart |

## OTP release

**28, and measured rather than assumed.** A new repository is the one moment when
changing release is free, because there are no recorded results to invalidate, so
29 was tested first. The dependency tree does not build on it: `reckon_gater` and
`khepri` both use the old-style `catch` that OTP 29 deprecates, and both build
with warnings as errors. The first is ours and is a short change; the second is
RabbitMQ's and needs an upstream release. The evidence and the exact sites are in
the `Containerfile`.

## Licence

Apache-2.0.
