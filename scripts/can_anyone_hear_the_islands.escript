#!/usr/bin/env escript
%%! -env ERL_LIBS _build/default/lib
%% ⚠ ERL_LIBS RATHER THAN A LIST OF `-pa' PATHS. The first version named the
%% handful of ebin directories it thought macula needed and
%% `application:ensure_all_started(macula)' returned happily with a supervisor
%% missing, so the first call into the SDK died with `noproc' about
%% `macula_peering_conn_sup'. A partial code path does not fail at startup, it
%% fails at the first use, several layers down, describing the wrong thing.
%% @doc DOES ANYTHING ACTUALLY COME OUT OF THE ISLANDS?
%%
%% Usage:  ./scripts/can_anyone_hear_the_islands.escript [station-url [seconds]]
%%
%% ==========================================================================
%% THE PUBLISH COUNTER WAS LYING, OR THE SUBSCRIBER IS. THIS TELLS THEM APART.
%% ==========================================================================
%%
%% The islands report `#{sent => 226, failed => 0}'. That counts what the SDK
%% ACCEPTED, not what any station carried and not what any subscriber received.
%% `macula:publish/4' is fire and forget, so an island dialling a station that
%% quietly drops its frames reports a clean run for ever.
%%
%% ⚠ THIS IS THE EXACT FAILURE THE SPECTATOR'S OWN MODULE DOCS WARN ABOUT, from
%% the other end: "silence that looks like success". It was written about
%% subscribing before a link is healthy. Nobody wrote the mirror of it about
%% publishing, and that is the gap this script exists to close.
%%
%% So: a third party, on a laptop, on the public realm, on the same topic. If
%% facts arrive here the islands are fine and the site is at fault. If they do
%% not, the site is fine and the islands have been shouting into a hole.
-mode(compile).

-define(PUBLIC_REALM,
        <<"659ee7725defd42e923cca72f51bbf6ecba9408dbaf4e3ca3f21b101d97cd051">>).
-define(DEFAULT_STATION, "https://station-de-frankfurt.macula.io:4433").
-define(DEFAULT_SECONDS, 40).

main(Args) ->
    Station = arg(Args, 1, ?DEFAULT_STATION),
    Seconds = list_to_integer(arg(Args, 2, integer_to_list(?DEFAULT_SECONDS))),
    application:ensure_all_started(macula),

    io:format("dialling ~s~n", [Station]),
    {ok, Pool} = macula:connect([Station], #{}),
    Realm = binary:decode_hex(?PUBLIC_REALM),

    %% ⚠ WAIT FOR A HEALTHY LINK BEFORE SUBSCRIBING. A connected pool is not a
    %% usable pool: subscribing in the handshake window does not fail, the
    %% station drops the frame, and `subscribe' still answers `{ok, Ref}'. That
    %% recorded lesson is the reason this script would otherwise reproduce the
    %% very bug it is investigating and blame the wrong end.
    ok = await_link(Pool, 40),

    Topic = <<"society/vitals">>,
    {ok, _Ref} = macula:subscribe(Pool, Realm, Topic, self()),
    io:format("subscribed ~s on the public realm, listening ~ps~n~n", [Topic, Seconds]),

    Heard = listen(Seconds * 1000, 0),
    io:format("~n~p facts in ~ps~n", [Heard, Seconds]),
    verdict(Heard).

verdict(0) ->
    io:format("NOTHING ARRIVED. The islands report clean publishes and no third~n"
              "party can hear them, so the fault is on the publishing side or in~n"
              "the station, and the site was never the problem.~n");
verdict(_N) ->
    io:format("THE ISLANDS ARE AUDIBLE from a third party, so the fault is in the~n"
              "site's subscriber and not in the islands.~n").

await_link(_Pool, 0) ->
    io:format("no healthy link after 40 tries, giving up~n"),
    error(no_link);
await_link(Pool, Left) ->
    case macula:status(Pool) of
        {ok, #{healthy_links := N}} when N > 0 ->
            io:format("link healthy (~p)~n", [N]),
            ok;
        _Other ->
            timer:sleep(500),
            await_link(Pool, Left - 1)
    end.

listen(Budget, Heard) when Budget =< 0 -> Heard;
listen(Budget, Heard) ->
    Started = erlang:monotonic_time(millisecond),
    receive
        {macula_event, _Ref, Topic, Payload, _Meta} ->
            io:format("  ~s  island=~p tick=~p~n",
                      [Topic, field(Payload, island), field(Payload, tick)]),
            listen(Budget - elapsed(Started), Heard + 1);
        Other ->
            %% ⚠ PRINTS THE WHOLE MESSAGE, NOT ITS TAG. The first version printed
            %% only `element(1, Other)', so fifteen delivered facts read as
            %% "(other message: macula_event)" and the script concluded NOTHING
            %% ARRIVED. The evidence was on screen and the summary contradicted
            %% it, which is worse than no diagnostic at all.
            io:format("  (unmatched: ~P)~n", [Other, 6]),
            listen(Budget - elapsed(Started), Heard)
    after Budget ->
        Heard
    end.

elapsed(Started) -> erlang:monotonic_time(millisecond) - Started.

%% The same key can arrive as an atom or as `{text, Binary}' depending on what
%% is in this node's atom table, which is the recorded CBOR trap. Both are tried
%% rather than assuming either.
field(Payload, Key) when is_map(Payload) ->
    Bin = atom_to_binary(Key, utf8),
    first_present([Key, Bin, {text, Bin}], Payload);
field(_Payload, _Key) ->
    unknown.

first_present([], _Map) -> undefined;
first_present([K | Rest], Map) -> found(maps:find(K, Map), Rest, Map).

found({ok, V}, _Rest, _Map) -> V;
found(error, Rest, Map) -> first_present(Rest, Map).

arg(Args, N, Default) when length(Args) >= N -> lists:nth(N, Args);
arg(_Args, _N, Default) -> Default.
