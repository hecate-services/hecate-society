%% @doc An island's name, its identity, and the fact that they are different.
-module(society_identity_tests).

-include_lib("eunit/include/eunit.hrl").

-define(CACHE, {society_identity, island_id}).

%% Each case gets its own data directory and a cleared cache, because
%% `island_id/0' remembers in a persistent_term deliberately: a fact goes out on
%% a timer and it must not become a file read per publish. That cache is exactly
%% what would make these cases contaminate each other.
with_fresh_data_dir(Body) ->
    Dir = filename:join("/tmp", "hecate_society_test_"
                        ++ integer_to_list(erlang:unique_integer([positive]))),
    Previous = os:getenv("HECATE_SOCIETY_DATA_DIR"),
    true = os:putenv("HECATE_SOCIETY_DATA_DIR", Dir),
    _ = persistent_term:erase(?CACHE),
    try Body(Dir)
    after
        _ = persistent_term:erase(?CACHE),
        restore("HECATE_SOCIETY_DATA_DIR", Previous),
        _ = file:del_dir_r(Dir)
    end.

restore(Var, false) -> os:unsetenv(Var);
restore(Var, Value) -> os:putenv(Var, Value).

with_name(Name, Body) ->
    Previous = os:getenv("HECATE_SOCIETY_ISLAND"),
    true = os:putenv("HECATE_SOCIETY_ISLAND", Name),
    try Body()
    after restore("HECATE_SOCIETY_ISLAND", Previous)
    end.

%%==============================================================================
%% The name, which a person types
%%==============================================================================

the_name_comes_from_the_environment_test() ->
    with_name("beam07", fun() ->
        ?assertEqual(<<"beam07">>, society_identity:island())
    end).

%% Whitespace around a value pasted into a config file is the operator's, not
%% part of the name, and an island called "beam07\n" would sort and match as a
%% different island everywhere.
the_name_is_trimmed_test() ->
    with_name("  beam07  ", fun() ->
        ?assertEqual(<<"beam07">>, society_identity:island())
    end).

%% Unset falls back to the host, because a machine already has an identity and
%% inventing a second one nobody configures produces a fleet of islands all
%% called the same thing.
an_unset_name_falls_back_to_the_host_test() ->
    Previous = os:getenv("HECATE_SOCIETY_ISLAND"),
    os:unsetenv("HECATE_SOCIETY_ISLAND"),
    try
        {ok, Host} = inet:gethostname(),
        ?assertEqual(list_to_binary(Host), society_identity:island())
    after restore("HECATE_SOCIETY_ISLAND", Previous)
    end.

renaming_changes_what_it_is_called_test() ->
    with_name("before", fun() ->
        ok = society_identity:set_island(<<"after">>),
        ?assertEqual(<<"after">>, society_identity:island())
    end).

%%==============================================================================
%% The identity, which nobody types
%%==============================================================================

an_identity_is_128_bits_of_lowercase_hex_test() ->
    with_fresh_data_dir(fun(_Dir) ->
        Id = society_identity:island_id(),
        ?assertEqual(32, byte_size(Id)),
        ?assertMatch({match, _}, re:run(Id, "^[0-9a-f]{32}$"))
    end).

it_is_minted_once_and_survives_a_restart_test() ->
    with_fresh_data_dir(fun(_Dir) ->
        First = society_identity:island_id(),
        %% Clearing the cache is what a restart looks like to this module: the
        %% process memory is gone and the file is not.
        _ = persistent_term:erase(?CACHE),
        ?assertEqual(First, society_identity:island_id())
    end).

two_islands_with_different_directories_never_collide_test() ->
    A = with_fresh_data_dir(fun(_Dir) -> society_identity:island_id() end),
    B = with_fresh_data_dir(fun(_Dir) -> society_identity:island_id() end),
    ?assertNotEqual(A, B).

%% ⚠ THE WHOLE POINT OF THE MODULE, ASSERTED. A rename must not touch the
%% identity, or the two would be one thing wearing two names and every reason the
%% separation exists would be undone silently.
renaming_does_not_change_the_identity_test() ->
    with_fresh_data_dir(fun(_Dir) ->
        with_name("before", fun() ->
            Id = society_identity:island_id(),
            ok = society_identity:set_island(<<"after">>),
            ?assertEqual(<<"after">>, society_identity:island()),
            ?assertEqual(Id, society_identity:island_id())
        end)
    end).

%% A write torn by a crash would otherwise give this island a blank identity for
%% ever, which is precisely the collision the identity exists to prevent. So a
%% file that exists and holds nothing usable is treated as absent.
a_truncated_identity_file_is_reminted_rather_than_trusted_test() ->
    with_fresh_data_dir(fun(Dir) ->
        Path = filename:join(Dir, "island.id"),
        ok = filelib:ensure_dir(Path),
        ok = file:write_file(Path, <<"0123456789">>),
        Id = society_identity:island_id(),
        ?assertEqual(32, byte_size(Id)),
        ?assertEqual({ok, Id}, file:read_file(Path))
    end).

an_empty_identity_file_is_reminted_test() ->
    with_fresh_data_dir(fun(Dir) ->
        Path = filename:join(Dir, "island.id"),
        ok = filelib:ensure_dir(Path),
        ok = file:write_file(Path, <<>>),
        ?assertEqual(32, byte_size(society_identity:island_id()))
    end).
