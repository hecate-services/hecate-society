# hecate-society
#
# One island: a people who hold beliefs, teach them, and decide who may land.
#
# ==========================================================================
# THE RUNTIME IS PINNED IN TWO PLACES AND THEY MUST AGREE
# ==========================================================================
#
# Here, and `.github/workflows/lint.yml'. On the predecessor they did not: this
# said 27 while development ran on 28, so a local `rebar3 eunit' meant "passing
# on 28" and nothing more. CI then failed for three commits on a crash that does
# not occur on 28 at all, and because `build-and-push' is a separate workflow the
# image went to the fleet regardless.
#
# ⚠ AND A RUN IS ONLY A PURE FUNCTION OF ITS SEED WITHIN ONE OTP RELEASE. `rand'
# and map iteration order are not promised to agree across releases, so seed 101
# is a different run on 28 and on 29. Every result this project records is a
# result about the release it was measured on.
#
# ==========================================================================
# WHY 28 AND NOT 29, MEASURED RATHER THAN ASSUMED
# ==========================================================================
#
# A new repository is the one moment when changing OTP release is free, because
# there are no recorded results for it to invalidate, and the cost of changing
# grows with every result after today. So 29 was the default and it was tested
# rather than adopted.
#
# ⚠ THE DEPENDENCY TREE DOES NOT BUILD ON 29, AND NOT ONLY BECAUSE OF US.
# OTP 29 deprecates the old-style `catch Expr', and two libraries in this tree
# use it while building with warnings as errors. Measured 2026-08-04, whole
# tree, same rebar.config, 29.0.2 against 28.4.2:
#
#     OTP 28.4.2   clean, compile exit 0
#     OTP 29.0.2   reckon_gater_repl.erl        FAILED   5 sites   ours
#                  khepri_import_export.erl     FAILED   2 sites   NOT ours
#
# rebar3 stops at the first failing application, so the second was found only by
# suppressing the first in a throwaway build directory and letting the compiler
# walk past it. Reporting reckon_gater alone would have understated this as one
# small fix away.
#
# reckon-gater is ours and is a short change. khepri is RabbitMQ's, arrives
# through reckon_db, and needs an UPSTREAM release. So 29 is not a decision this
# project can take on its own, and it is not close. When both land, this pin and
# lint.yml's move together and the note stays, so the reason is not rediscovered
# by whoever next thinks 29 looks free.
FROM docker.io/erlang:28-alpine AS builder
WORKDIR /build

# macula ships a QUIC NIF. MACULA_FORCE_SOURCE_BUILD makes it build here rather
# than fetch a prebuilt binary linked against a different libc, which is the
# recorded glibc trap: the fetched artifact loads on the build host and fails on
# alpine at runtime.
RUN apk add --no-cache git curl bash build-base cmake perl linux-headers
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
        | sh -s -- -y --default-toolchain stable --profile minimal
ENV PATH="/root/.cargo/bin:${PATH}"
ENV RUSTFLAGS="-C target-feature=-crt-static"
ENV MACULA_FORCE_SOURCE_BUILD=1

RUN curl -fsSL https://s3.amazonaws.com/rebar3/rebar3 -o /usr/local/bin/rebar3 \
    && chmod +x /usr/local/bin/rebar3

# Dependencies resolve from rebar.config alone, so this layer survives every
# change to config/ and apps/ and the Rust toolchain is not re-run per commit.
COPY rebar.config ./
RUN rebar3 get-deps

COPY config ./config
COPY apps ./apps
RUN rebar3 as prod release

FROM docker.io/alpine:3.22
# LINKS THE PACKAGE TO THE REPO. Without it a ghcr package is an orphan: it does
# not appear on the repo page and does not inherit the repo's visibility. A
# sibling shipped private by accident this way and the deploy failed on the node
# with a bare "unauthorized" from the pull, which names nothing.
LABEL org.opencontainers.image.source="https://github.com/hecate-services/hecate-society"
RUN apk add --no-cache ncurses-libs libstdc++ libgcc openssl ca-certificates curl
WORKDIR /app
COPY --from=builder /build/_build/prod/rel/hecate_society ./

ENV HOME=/app
ENV RELX_REPLACE_OS_VARS=true

ENV HECATE_NODE_NAME=hecate_society
ENV HECATE_NODE_HOST=127.0.0.1
ENV HECATE_COOKIE=hecate_society
# Clear of the siblings: 8450, 8471, 8481, 8482 and 8483 are taken across the
# fleet, and host networking makes a collision a silent bind failure.
ENV HECATE_HEALTH_PORT=8484

VOLUME ["/etc/hecate/secrets"]

EXPOSE 8484
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD curl -fsS "http://127.0.0.1:${HECATE_HEALTH_PORT}/health" || exit 1

CMD ["/app/bin/hecate_society", "foreground"]
