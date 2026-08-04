%% @doc The service contract, asserted locally.
%%
%% hecate_om resolves its six callbacks BY NAME at startup, on a live node, so a
%% service that forgets one dies with `undef' where nobody is watching. Two
%% sibling services recorded exactly that failure. The primary defence is the
%% `-behaviour(hecate_om_service)' attribute on the service module, which turns a
%% missing callback into a compile error under warnings_as_errors.
%%
%% What this suite adds is everything the compiler cannot see: that the attribute
%% has not been quietly dropped, that the values inside those callbacks are the
%% shapes hecate_om will destructure, and that the version this service reports
%% is the version it actually is. Nothing local boots hecate_om, so asserting the
%% shape by hand is the closest available thing to a rehearsal.
-module(hecate_society_service_tests).

-include_lib("eunit/include/eunit.hrl").

-define(SERVICE, hecate_society_service).

%% Belt and braces with the behaviour attribute, and it survives the attribute
%% being removed. If hecate_om ever adds a SEVENTH required callback this test
%% keeps passing and the deploy still breaks, which is the honest limit of a
%% local assertion about a remote contract.
exports_every_required_callback_test() ->
    _ = code:ensure_loaded(?SERVICE),
    Required = [{info, 0}, {start, 1}, {stop, 1},
                {health, 0}, {capabilities, 0}, {identity_spec, 0}],
    Missing = [F || {N, A} = F <- Required,
                    not erlang:function_exported(?SERVICE, N, A)],
    ?assertEqual([], Missing).

info_carries_the_three_keys_test() ->
    #{name := Name, version := Vsn, description := Desc} = ?SERVICE:info(),
    ?assert(is_binary(Name)),
    ?assert(is_binary(Vsn)),
    ?assert(is_binary(Desc)),
    ?assertEqual(<<"hecate-society">>, Name).

%% The version in info/0 is what a peer reads off /health, so it disagreeing with
%% the application it describes is a lie that nothing else would catch.
info_version_matches_the_application_test() ->
    _ = application:load(hecate_society),
    {ok, Vsn} = application:get_key(hecate_society, vsn),
    #{version := Reported} = ?SERVICE:info(),
    ?assertEqual(list_to_binary(Vsn), Reported).

health_is_green_test() ->
    ?assertEqual(ok, ?SERVICE:health()).

identity_spec_has_the_shape_hecate_om_expects_test() ->
    Spec = ?SERVICE:identity_spec(),
    #{scope := Scope, actions := Actions,
      resources := Resources, ttl_days := Ttl} = Spec,
    ?assert(is_binary(Scope)),
    ?assert(is_list(Actions)),
    ?assert(is_list(Resources)),
    ?assert(is_integer(Ttl) andalso Ttl > 0).

%% THE AUTHORITY MUST MATCH WHAT THE CODE ACTUALLY DOES, IN BOTH DIRECTIONS.
%% Asking for a topic it never publishes to is authority handed over for nothing;
%% publishing to a topic it never asked for is a call the realm would refuse once
%% UCAN delegation lands. A sibling drifted exactly this way, quietly publishing
%% on two topics its spec did not name.
%%
%% ⚠ THIS ISLAND PUBLISHES NOTHING, SO IT ASKS FOR NOTHING, and this test is
%% written to FAIL the day the first publish lands without the spec moving with
%% it. That is its whole job: an empty list here is a claim about the code, not a
%% placeholder.
authority_covers_every_topic_published_and_no_more_test() ->
    #{actions := Actions, resources := Resources} = ?SERVICE:identity_spec(),
    ?assertEqual([<<"publish">>], Actions),
    ?assertEqual([], Resources).

%% It speaks and takes no requests, so it promises nothing another service could
%% call. Accepting a migrant would be a capability, and this fails when that
%% happens, which is the point.
announces_nothing_callable_test() ->
    ?assertEqual([], ?SERVICE:capabilities()).

%% The tree starts WITHOUT hecate_om, which is the property that matters: the
%% mesh is an output, not a dependency. An island that could not boot without a
%% station would be a people who need a boat in order to exist, and CHARTER.md
%% makes a partition a geographic barrier rather than an outage.
supervisor_starts_empty_test() ->
    {ok, Pid} = hecate_society_sup:start_link(),
    ?assert(is_process_alive(Pid)),
    ?assertEqual([], supervisor:which_children(Pid)),
    unlink(Pid),
    exit(Pid, shutdown).

%%==============================================================================
%% The config the store cannot boot without
%%==============================================================================

%% ⚠ THE PREDECESSOR'S FLEET CRASH-LOOPED ON TWO OF THREE NODES FOR WANT OF THIS
%% BLOCK.
%%
%% Exporting `store_id/0' makes `hecate_om:boot/1' start the store AND a
%% per-store evoq subscription. That subscription reads through evoq, which
%% raises `{not_configured, event_store_adapter}' unless sys.config names the
%% adapter. evoq starts as a release-boot application before any service's
%% `start/2' runs, so nothing can inject it later.
%%
%% `hecate_om_store' documents this precisely, in its own module header, calling
%% it MANDATORY. There the callbacks were added without reading it.
%%
%% This test reads the shipped config template, because the failure is a MISSING
%% BLOCK and no amount of exercising the code can notice something that is not
%% there. It is the boundary guard CHARTER.md's rule 6 asks for: it compares the
%% Erlang side against the config side, and no test of either alone can see it.
the_evoq_adapter_is_configured_wherever_a_store_is_opened_test() ->
    {ok, Text} = file:read_file(alongside("config/sys.config.src")),
    ?assert(erlang:function_exported(hecate_society_service, store_id, 0)),
    lists:foreach(
      fun(Needed) ->
              ?assertNotEqual(nomatch, binary:match(Text, Needed),
                              {missing_from_sys_config, Needed})
      end,
      [<<"{evoq,">>, <<"event_store_adapter">>, <<"subscription_adapter">>,
       <<"reckon_evoq_adapter">>]).

%% ⚠ AND THE STORE ID IS IN TWO PLACES, WHICH IS ONE MORE THAN IT SHOULD BE.
%% `store_id/0' is what hecate_om opens; the `{store_id, ...}' in the evoq block
%% is what evoq falls back to when it resolves a dispatch before knowing there is
%% none. Nothing makes them agree, and disagreeing would open one store and
%% address another. Same boundary guard, other side.
the_store_id_agrees_between_erlang_and_config_test() ->
    {ok, Text} = file:read_file(alongside("config/sys.config.src")),
    Declared = atom_to_binary(hecate_society_service:store_id(), utf8),
    ?assertNotEqual(nomatch, binary:match(Text, Declared),
                    {store_id_not_in_sys_config, Declared}).

%%==============================================================================
%% The runtime is pinned in two places, and neither is the one you are running
%%==============================================================================

%% ⚠ THIS IS THE GUARD THE PREDECESSOR DID NOT HAVE, AND IT COST IT THREE COMMITS.
%%
%% Its `Containerfile' said 27 while development ran on 28. So `rebar3 eunit'
%% passing locally meant "passing on 28" and nothing more, CI failed on a crash
%% that does not occur on 28 at all, and because the image build is a separate
%% workflow the image went to the fleet regardless.
%%
%% The pin exists in two files and the version actually running is a third thing
%% that agrees with neither by default. **A comment in each file saying they must
%% match is not a mechanism**, and both files carried one.
%%
%% ⚠⚠ IT FAILS RATHER THAN WARNS WHEN YOUR VM DIFFERS, AND THAT IS DELIBERATE.
%% Developing on a release you do not ship makes a green suite mean less than it
%% appears to, and a run is only a pure function of its seed WITHIN one OTP
%% release. If you want to work on another one, move the pins and find out what
%% breaks, which is the whole point.
the_runtime_agrees_between_the_image_the_ci_and_this_vm_test() ->
    Image = pinned("Containerfile", "FROM docker.io/erlang:([0-9]+)"),
    Ci = pinned(".github/workflows/lint.yml", "image: erlang:([0-9]+)"),
    Running = list_to_binary(erlang:system_info(otp_release)),
    %% Sorted and deduplicated, so a failure prints all three rather than the
    %% first pair that happened to be compared.
    ?assertEqual([Image], lists:usort([Image, Ci, Running])).

pinned(Relative, Pattern) ->
    {ok, Text} = file:read_file(alongside(Relative)),
    {match, [Version]} = re:run(Text, Pattern,
                                [{capture, all_but_first, binary}]),
    Version.

%% Relative to the beam rather than the working directory, because eunit runs
%% from wherever the developer happens to be standing.
alongside(Name) -> climb(filename:dirname(code:which(?MODULE)), Name, 8).

climb(_Dir, Name, 0) -> Name;
climb(Dir, Name, Left) ->
    Candidate = filename:join(Dir, Name),
    found(filelib:is_regular(Candidate), Candidate, Dir, Name, Left).

found(true, Candidate, _Dir, _Name, _Left) -> Candidate;
found(false, _Candidate, Dir, Name, Left) ->
    climb(filename:dirname(Dir), Name, Left - 1).
