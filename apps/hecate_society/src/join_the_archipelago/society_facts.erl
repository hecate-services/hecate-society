%% @doc WHAT AN ISLAND SAYS ABOUT ITSELF, AND WHERE IT SAYS IT. PURE.
%%
%% ONE FACT SO FAR, `society/vitals': counts, and the nine need means. Small
%% enough to keep for ever, which is what a statistics reader wants.
%%
%% THE ISLAND ID IS IN THE PAYLOAD AND NEVER IN THE TOPIC. Putting it in the topic
%% is the mistake that scales worst: a thousand islands become a thousand topics,
%% subscription management collapses, and a reader who wants "all islands" cannot
%% ask for it. One topic, an `island_id' field, and a subscriber filters. The
%% namespace separates whole DEPLOYMENTS, not islands.
%%
%% TOTALS RATHER THAN RATES, because a rate is recoverable from two totals and a
%% total is not recoverable from rates. A reader that misses a fact can still work
%% out what happened across the gap.
%%
%% THE TICK IS ON EVERY FACT, and it is not decoration. Publishing runs on wall
%% clock and the island runs on its own pace, so two consecutive facts may be one
%% tick apart or a million. Without the tick a reader cannot tell a stalled island
%% from a slow one.
%%
%% ==========================================================================
%% ⚠ THE AXIS NAMES TRAVEL WITH THE VECTOR, AND THAT IS NEW
%% ==========================================================================
%%
%% The predecessor sent flat integer lists whose meaning was positional, and
%% required every reader to MIRROR the field order in its own source. Its own
%% notes call that the mirror's risk, and then it happened: world 23 appended a
%% fifth field, the site's mirror did not follow, and the first four indexes went
%% on decoding correctly so nothing looked wrong.
%%
%% Nine atoms is a handful of bytes per fact and it removes the whole class of
%% fault. **A reader never has to know the order, and an island a version ahead
%% is self-describing.**
%%
%% ==========================================================================
%% WIRE RULES, EACH EARNED BY SOMETHING THAT BROKE
%% ==========================================================================
%%
%% Atom keys only, no tuples as values, integers rather than floats. A tuple does
%% not survive the encoder cleanly, and an atom key and a binary key of the same
%% name collide into one.
%%
%% ⚠ AND THE NEED VECTOR IS NEVER SUMMED. Charter rule 9. There is no `welfare'
%% field and there will not be one: the axes are incommensurable, so any total
%% would be a weighting, and a weighting is somebody's culture rather than a
%% measurement.
-module(society_facts).

-export([topic/1, topics/0, namespace/0, fact_version/0]).
-export([vitals/1]).

-define(DEFAULT_NS, <<"society">>).

%% ⚠ BUMPED WHENEVER THE SHAPE CHANGES, INCLUDING AN APPEND. A reader has no
%% other way to ask "is the field I want in this frame, or am I talking to an
%% island that predates it". 1 is the first fact this track ever published.
-define(FACT_VERSION, 1).

-spec fact_version() -> pos_integer().
fact_version() -> ?FACT_VERSION.

%% Topics are `<namespace>/<leaf>'. The namespace tells one deployment from
%% another, for instance a laptop from the fleet, and is NOT how islands are
%% distinguished.
-spec topic(atom()) -> binary().
topic(vitals) -> leaf(<<"vitals">>).

%% @doc Every topic this island publishes on.
%%
%% ⚠ EXPORTED SO THE SERVICE'S `identity_spec/0' CAN ASK FOR EXACTLY THESE AND NO
%% MORE, and so a test can compare the two. Authority that names a topic nothing
%% publishes to is a credential lying around; publishing to a topic the spec does
%% not name is a call the realm would refuse once delegation lands. A sibling
%% drifted exactly that way.
-spec topics() -> [binary()].
topics() -> [topic(vitals)].

leaf(Leaf) -> <<(namespace())/binary, "/", Leaf/binary>>.

-spec namespace() -> binary().
namespace() -> ns(os:getenv("HECATE_SOCIETY_NS")).

ns(false) -> ?DEFAULT_NS;
ns("") -> ?DEFAULT_NS;
ns(Str) -> list_to_binary(string:trim(Str)).

%% @doc What this island is, right now.
%%
%% Takes the island rather than reading anything, so it stays pure and a test can
%% build one without a running node.
-spec vitals(island:island()) -> map().
vitals(Island) ->
    Tally = island:satisfier_tally(Island),
    #{fact_version => ?FACT_VERSION,
      island => society_identity:island(),
      island_id => society_identity:island_id(),
      tick => island:tick_of(Island),
      persons => island:population(Island),
      capacity => island:capacity(Island),
      %% ⚠ NINE NUMBERS AND THE NINE NAMES THAT GO WITH THEM. Never a total.
      axes => need:axes(),
      needs => island:need_means(Island),
      %% The rates actually in force, so a reader can see crowding without
      %% inferring it from a falling mean that has several possible causes.
      decay => island:effective_decay(Island),
      acts => island:acts(Island),
      deaths => island:deaths(Island),
      births => island:births(Island),
      satisfiers => length(island:catalogue(Island)),
      %% ⚠ EVERY CLASS PRESENT EVEN AT ZERO. A reader that has to tell "no
      %% violators" from "this island does not report violators" cannot, and a
      %% key that appears only sometimes is a field a chart silently drops.
      synergic => maps:get(synergic, Tally),
      singular => maps:get(singular, Tally),
      inhibiting => maps:get(inhibiting, Tally),
      pseudo => maps:get(pseudo, Tally),
      violator => maps:get(violator, Tally)}.
