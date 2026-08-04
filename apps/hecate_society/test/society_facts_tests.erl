%% @doc The first fact this track ever publishes, and the rules it must obey.
%%
%% Every rule here was earned by something that broke elsewhere, and none of them
%% can be checked by exercising the island: they are properties of the shape that
%% leaves the node.
-module(society_facts_tests).

-include_lib("eunit/include/eunit.hrl").

fact() -> society_facts:vitals(island:new(#{people => 20, lifespan => 30, seed => 3})).

with_data_dir(Body) ->
    Dir = filename:join("/tmp", "hecate_society_facts_"
                        ++ integer_to_list(erlang:unique_integer([positive]))),
    Previous = os:getenv("HECATE_SOCIETY_DATA_DIR"),
    true = os:putenv("HECATE_SOCIETY_DATA_DIR", Dir),
    _ = persistent_term:erase({society_identity, island_id}),
    try Body()
    after
        _ = persistent_term:erase({society_identity, island_id}),
        restore("HECATE_SOCIETY_DATA_DIR", Previous),
        _ = file:del_dir_r(Dir)
    end.

restore(Var, false) -> os:unsetenv(Var);
restore(Var, Value) -> os:putenv(Var, Value).

%%==============================================================================
%% Wire rules
%%==============================================================================

%% ⚠ ATOM KEYS ONLY. CBOR encodes an atom and a binary identically, and the
%% decoder resolves a text string to an existing atom when the receiving node
%% happens to have one. A map mixing the two shapes ships as two keys and arrives
%% as one, and the newer SDK rejects the frame outright.
every_key_is_an_atom_test() ->
    with_data_dir(fun() ->
        ?assert(lists:all(fun is_atom/1, maps:keys(fact())))
    end).

%% ⚠ NO TUPLES. A tuple does not survive the encoder cleanly, which is the oldest
%% wire rule here. Lists and integers travel; pairs do not.
no_value_is_a_tuple_test() ->
    with_data_dir(fun() ->
        ?assertEqual([], [K || {K, V} <- maps:to_list(fact()), is_tuple(V)])
    end).

%% ⚠ INTEGERS RATHER THAN FLOATS. Levels are per-mille for exactly this reason:
%% a number that becomes a fact should be an integer from the start rather than a
%% float somebody remembers to round at the boundary.
no_number_is_a_float_test() ->
    with_data_dir(fun() ->
        Numbers = lists:flatten([flatten_number(V) || V <- maps:values(fact())]),
        ?assertEqual([], [N || N <- Numbers, is_float(N)])
    end).

flatten_number(V) when is_list(V) -> [X || X <- V, is_number(X)];
flatten_number(V) when is_number(V) -> [V];
flatten_number(_Other) -> [].

a_reader_can_tell_which_shape_it_is_looking_at_test() ->
    with_data_dir(fun() ->
        #{fact_version := V} = fact(),
        ?assert(is_integer(V) andalso V > 0)
    end).

%%==============================================================================
%% The nine, and the reason the names travel with them
%%==============================================================================

%% ⚠ THE AXIS NAMES TRAVEL WITH THE VECTOR, WHICH THE PREDECESSOR DID NOT DO.
%% There a reader had to MIRROR the field order in its own source, and when world
%% 23 appended a fifth field the mirror did not follow: the first four indexes
%% went on decoding correctly, so nothing looked wrong and a reader simply could
%% not name the new one. Nine atoms per fact removes the whole class of fault.
the_axis_names_travel_with_the_vector_test() ->
    with_data_dir(fun() ->
        #{axes := Axes, needs := Needs} = fact(),
        ?assertEqual(need:axes(), Axes),
        ?assertEqual(length(Axes), length(Needs)),
        ?assertEqual(9, length(Needs))
    end).

the_decay_rates_are_published_so_crowding_is_visible_test() ->
    with_data_dir(fun() ->
        #{decay := Decay, axes := Axes} = fact(),
        ?assertEqual(length(Axes), length(Decay))
    end).

%% ⚠ RULE 9 ON THE WIRE. No total, no welfare, no score. The axes are
%% incommensurable, so any single number would be a weighting, and a weighting is
%% somebody's culture rather than a measurement. This is the last place it could
%% be smuggled in, because a chart wants one number and whoever writes the chart
%% will be tempted.
the_fact_carries_no_total_test() ->
    with_data_dir(fun() ->
        Keys = maps:keys(fact()),
        ?assertEqual([], [K || K <- Keys,
                               lists:member(K, [welfare, total, score, happiness,
                                                wellbeing, satisfaction])])
    end).

%% Every satisfier class present even at zero, so a reader can tell "no
%% violators" from "this island does not report violators". A key that appears
%% only sometimes is a field a chart silently drops.
every_satisfier_class_is_named_even_at_zero_test() ->
    with_data_dir(fun() ->
        F = fact(),
        lists:foreach(fun(Class) -> ?assert(maps:is_key(Class, F)) end,
                      satisfier:classes()),
        ?assertEqual(0, maps:get(violator, F))
    end).

%%==============================================================================
%% Identity and topics
%%==============================================================================

%% The island's name is a nickname two islands can share; its identity is 128 bits
%% nobody types. Both travel, because a reader files under one and shows the other.
both_the_name_and_the_identity_travel_test() ->
    with_data_dir(fun() ->
        #{island := Name, island_id := Id} = fact(),
        ?assert(is_binary(Name)),
        ?assertEqual(32, byte_size(Id))
    end).

%% ⚠ THE IDENTITY IS IN THE PAYLOAD AND NEVER IN THE TOPIC. A thousand islands
%% would otherwise be a thousand topics, subscription management would collapse,
%% and a reader who wants "all islands" could not ask for it.
the_topic_does_not_carry_the_island_test() ->
    with_data_dir(fun() ->
        Topic = society_facts:topic(vitals),
        #{island_id := Id} = fact(),
        ?assertEqual(nomatch, binary:match(Topic, Id)),
        ?assertEqual(<<"society/vitals">>, Topic)
    end).

the_namespace_separates_deployments_not_islands_test() ->
    Previous = os:getenv("HECATE_SOCIETY_NS"),
    true = os:putenv("HECATE_SOCIETY_NS", "laptop"),
    try
        ?assertEqual(<<"laptop/vitals">>, society_facts:topic(vitals))
    after restore("HECATE_SOCIETY_NS", Previous)
    end.

topics_lists_exactly_what_is_published_test() ->
    ?assertEqual([society_facts:topic(vitals)], society_facts:topics()).

%% The tick is on every fact and it is not decoration: publishing runs on wall
%% clock and the island on its own pace, so without it a reader cannot tell a
%% stalled island from a slow one.
the_tick_is_on_the_fact_test() ->
    with_data_dir(fun() ->
        #{tick := T} = society_facts:vitals(
                         island:run(island:new(#{people => 5, seed => 1}), 7)),
        ?assertEqual(7, T)
    end).
