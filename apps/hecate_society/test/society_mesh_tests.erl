%% @doc The mesh edge, exercised with no mesh behind it.
%%
%% THAT IS THE PROPERTY WORTH TESTING AND IT IS NOT AN EDGE CASE. CHARTER.md
%% makes a partition a geographic barrier rather than an outage, so "no mesh" is
%% a state the design is about, not a state it tolerates. Every function here
%% must return an error the caller can shrug at, and none may raise, because an
%% exception on this path travels up a publish timer and kills the island,
%% taking the people on it with it.
%%
%% hecate_om is not running in eunit, so `hecate_om_identity:macula_client/0'
%% finds no mesh pool and returns {error, no_client}. That is the realistic
%% failure: it is what happens on a live node while hecate_om is restarting.
-module(society_mesh_tests).

-include_lib("eunit/include/eunit.hrl").

with_realm(Value, Body) ->
    Previous = os:getenv("HECATE_SOCIETY_REALM"),
    set("HECATE_SOCIETY_REALM", Value),
    try Body()
    after set("HECATE_SOCIETY_REALM", Previous)
    end.

set(Var, false) -> os:unsetenv(Var);
set(Var, Value) -> os:putenv(Var, Value).

%%==============================================================================
%% Nothing here may raise
%%==============================================================================

publishing_into_a_dark_mesh_returns_an_error_test() ->
    ?assertMatch({error, _}, society_mesh:publish(<<"society/vitals">>, #{a => 1})).

asking_for_the_door_of_a_dark_mesh_returns_an_error_test() ->
    ?assertMatch({error, _}, society_mesh:station()).

availability_is_false_rather_than_an_exception_test() ->
    ?assertEqual(false, society_mesh:available()).

%% The failure must NAME the missing thing. A bare `{error, failed}' on this path
%% is the difference between "the mesh is not up yet" and "the island crashed",
%% which is the exact distinction a supervisor exit destroys.
the_error_names_what_was_missing_test() ->
    {error, Reason} = society_mesh:publish(<<"society/vitals">>, #{}),
    ?assertMatch({no_macula_client, {error, no_client}}, Reason).

%%==============================================================================
%% Which realm the facts go out on
%%==============================================================================

%% Unset falls back, so a deployment that has not been told about the public
%% realm keeps behaving as it did rather than going silent.
an_unset_realm_falls_back_to_the_fleet_test() ->
    with_realm(false, fun() ->
        ?assertEqual({ok, <<"fleet">>}, society_mesh:publish_realm(<<"fleet">>))
    end).

an_empty_realm_falls_back_to_the_fleet_test() ->
    with_realm("", fun() ->
        ?assertEqual({ok, <<"fleet">>}, society_mesh:publish_realm(<<"fleet">>))
    end).

a_valid_tag_decodes_to_thirty_two_bytes_test() ->
    Hex = "659ee7725defd42e923cca72f51bbf6ecba9408dbaf4e3ca3f21b101d97cd051",
    with_realm(Hex, fun() ->
        {ok, Realm} = society_mesh:publish_realm(<<"fleet">>),
        ?assertEqual(32, byte_size(Realm))
    end).

%% ⚠ A MALFORMED TAG IS AN ERROR AND MUST NEVER FALL BACK. Falling back on a typo
%% would publish PUBLIC facts onto the OPERATIONAL realm and report success,
%% which is the one outcome nobody would notice.
a_short_tag_is_an_error_rather_than_a_fallback_test() ->
    with_realm("abc123", fun() ->
        ?assertEqual({error, society_realm_not_64_hex},
                     society_mesh:publish_realm(<<"fleet">>))
    end).

a_tag_of_the_right_length_that_is_not_hex_is_an_error_test() ->
    NotHex = lists:duplicate(64, $z),
    with_realm(NotHex, fun() ->
        ?assertEqual({error, society_realm_not_hex},
                     society_mesh:publish_realm(<<"fleet">>))
    end).

%% Whitespace from a config file is the operator's, not part of the tag.
a_tag_is_trimmed_before_it_is_judged_test() ->
    Hex = "  659ee7725defd42e923cca72f51bbf6ecba9408dbaf4e3ca3f21b101d97cd051  ",
    with_realm(Hex, fun() ->
        ?assertMatch({ok, _}, society_mesh:publish_realm(<<"fleet">>))
    end).

%%==============================================================================
%% The boundary guard
%%==============================================================================

%% ⚠ THE PUBLIC REALM IS WRITTEN IN THREE PLACES AND NOTHING MAKES THEM AGREE:
%% this module's header, the compose file in macula-demo, and whatever subscribes
%% on the spectator's side. Only the first is reachable from here, so this checks
%% what it can: that the tag named in the docs is the sha256 of the name named
%% beside it. A tag that drifts from its name is a fact published where nobody is
%% listening, and it looks exactly like a healthy island.
the_documented_public_realm_is_the_hash_of_its_documented_name_test() ->
    Documented = <<"659ee7725defd42e923cca72f51bbf6ecba9408dbaf4e3ca3f21b101d97cd051">>,
    Computed = string:lowercase(
                 binary:encode_hex(crypto:hash(sha256, <<"net.beamcampus.society">>))),
    ?assertEqual(Documented, Computed),
    {ok, Source} = file:read_file(alongside("apps/hecate_society/src/join_the_archipelago/society_mesh.erl")),
    ?assertNotEqual(nomatch, binary:match(Source, Documented)),
    ?assertNotEqual(nomatch, binary:match(Source, <<"net.beamcampus.society">>)).

alongside(Name) -> climb(filename:dirname(code:which(?MODULE)), Name, 8).

climb(_Dir, Name, 0) -> Name;
climb(Dir, Name, Left) ->
    Candidate = filename:join(Dir, Name),
    found(filelib:is_regular(Candidate), Candidate, Dir, Name, Left).

found(true, Candidate, _Dir, _Name, _Left) -> Candidate;
found(false, _Candidate, Dir, Name, Left) ->
    climb(filename:dirname(Dir), Name, Left - 1).
