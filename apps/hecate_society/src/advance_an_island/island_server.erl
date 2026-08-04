%% @doc Owns this node's island and keeps it moving.
%%
%% Two timers, deliberately separate. The island advances on its own pace and
%% publishes on wall clock, because a world you WATCH and a world you SEARCH want
%% different rates and the predecessor spent worlds discovering that one number
%% cannot serve both.
%%
%% ⚠ A DARK MESH IS NOT A FAILURE OF THE ISLAND. `CHARTER.md' makes a partition a
%% geographic barrier rather than an outage: the people carry on living and the
%% only thing lost is that nobody else hears about it. So a publish that cannot
%% happen is counted and shrugged at, and `society_mesh' returns an error rather
%% than raising precisely so that this timer cannot kill the island.
%%
%% RESTARTING LOSES THE ISLAND, and that is the honest behaviour rather than an
%% oversight. Nothing is persisted yet, so a crash means the people who were
%% alive are gone and a fresh population is seeded. Making that survive means
%% deciding what an island owes the future, which is a real question and not a
%% line of supervisor configuration.
-module(island_server).

-behaviour(gen_server).

-export([start_link/0, snapshot/0, island/0, publishes/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2]).

-define(DEFAULT_TICKS_PER_SLOT, 1).
-define(DEFAULT_SLOT_MS, 500).
-define(DEFAULT_PUBLISH_MS, 1000).

start_link() -> gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% @doc The published shape, without needing a mesh. What a local page would draw.
-spec snapshot() -> map().
snapshot() -> gen_server:call(?MODULE, snapshot).

%% @doc The island itself, for a script that wants to measure rather than watch.
-spec island() -> island:island().
island() -> gen_server:call(?MODULE, island).

%% @doc How many facts went out, and how many could not.
-spec publishes() -> #{sent := non_neg_integer(), failed := non_neg_integer()}.
publishes() -> gen_server:call(?MODULE, publishes).

%%==============================================================================
%% gen_server
%%==============================================================================

init([]) ->
    Island = island:new(from_env()),
    schedule(tick, slot_ms()),
    schedule(publish, publish_ms()),
    {ok, #{island => Island, sent => 0, failed => 0}}.

handle_call(snapshot, _From, #{island := I} = S) ->
    {reply, society_facts:vitals(I), S};
handle_call(island, _From, #{island := I} = S) ->
    {reply, I, S};
handle_call(publishes, _From, #{sent := Sent, failed := Failed} = S) ->
    {reply, #{sent => Sent, failed => Failed}, S};
handle_call(_Other, _From, S) ->
    {reply, {error, unknown_call}, S}.

handle_cast(_Msg, S) -> {noreply, S}.

handle_info(tick, #{island := I} = S) ->
    schedule(tick, slot_ms()),
    {noreply, S#{island := island:run(I, ticks_per_slot())}};
handle_info(publish, #{island := I} = S) ->
    schedule(publish, publish_ms()),
    {noreply, counted(society_mesh:publish(society_facts:topic(vitals),
                                           society_facts:vitals(I)), S)};
handle_info(_Msg, S) ->
    {noreply, S}.

%% ⚠ COUNTED RATHER THAN LOGGED. `CHARTER.md' rule 3: a capacity that was never
%% exercised is not evidence of anything, so the exercise count is published
%% beside every null. An island that has published nothing and an island whose
%% every publish failed look identical in a log and are different questions.
counted(ok, #{sent := N} = S) -> S#{sent := N + 1};
counted({error, _Why}, #{failed := N} = S) -> S#{failed := N + 1}.

schedule(Msg, Ms) -> erlang:send_after(Ms, self(), Msg).

%%==============================================================================
%% Configuration
%%==============================================================================

%% ⚠ A NODE CONFIG MAY NAME WHAT A NODE IS AND NEVER WHAT THE PHYSICS ARE.
%% Recorded rule, and it cost the predecessor a two-hour boot-crash loop: an
%% economy constant sat in a deployment repo on a different release cadence, the
%% node pulled the config naming a key before the image that had it, and the
%% service refused to start. Correctly.
%%
%% So: the seed and the pace come from the environment, because they say which
%% RUN this is and how fast to watch it. The decay rates, the catalogue and the
%% crowding axis do not, because they are the physics and they ship with the
%% image or they are not physics.
from_env() ->
    Base = #{},
    maps:merge(Base, seeded(os:getenv("HECATE_SOCIETY_SEED"))).

seeded(false) -> #{};
seeded("") -> #{};
seeded(Str) -> #{seed => list_to_integer(string:trim(Str))}.

ticks_per_slot() -> positive_env("HECATE_SOCIETY_TICKS_PER_SLOT", ?DEFAULT_TICKS_PER_SLOT).
slot_ms() -> positive_env("HECATE_SOCIETY_SLOT_MS", ?DEFAULT_SLOT_MS).
publish_ms() -> positive_env("HECATE_SOCIETY_PUBLISH_MS", ?DEFAULT_PUBLISH_MS).

%% A malformed or non-positive value falls back rather than crashing the island.
%% A typo in a pace variable should cost the default pace, not the people.
positive_env(Name, Default) -> usable(os:getenv(Name), Default).

usable(false, Default) -> Default;
usable("", Default) -> Default;
usable(Str, Default) -> parsed(string:to_integer(string:trim(Str)), Default).

parsed({N, ""}, _Default) when N > 0 -> N;
parsed(_Unusable, Default) -> Default.
