%% @doc The nine axes, the practices, and one tick of a people's life.
-module(advance_an_island_tests).

-include_lib("eunit/include/eunit.hrl").

small() -> #{people => 40, capacity => 50, lifespan => 30, seed => 7}.

%%==============================================================================
%% The axes, and the rule that keeps them cheap
%%==============================================================================

%% ⚠ WIRE ORDER, PINNED. Every published need vector is nine numbers in this
%% order and a reader maps them by position. Swapping two entries would silently
%% relabel every measurement ever taken, and nothing else would look wrong.
the_axes_are_these_nine_in_this_order_test() ->
    ?assertEqual([subsistence, protection, affection, understanding, participation,
                  leisure, creation, identity, freedom],
                 need:axes()),
    ?assertEqual(9, need:count()).

an_axis_knows_its_own_position_test() ->
    ?assertEqual(1, need:index_of(subsistence)),
    ?assertEqual(9, need:index_of(freedom)),
    ?assertEqual(subsistence, need:name_of(1)),
    ?assertEqual(freedom, need:name_of(9)).

%% A typo in a satisfier's claim should fail where it is written rather than
%% quietly claim to serve axis zero.
an_unknown_axis_is_refused_rather_than_guessed_test() ->
    ?assertError({not_an_axis, wealth}, need:index_of(wealth)).

%% ⚠ RULE 8 AS A TEST. Every axis must be reachable by index and nothing may
%% require a function named after it. If a tenth axis is ever added, this is what
%% says whether it cost data or code.
every_axis_is_reachable_by_index_alone_test() ->
    Names = [need:name_of(N) || N <- lists:seq(1, need:count())],
    ?assertEqual(need:axes(), Names).

decay_takes_each_axis_at_its_own_rate_test() ->
    Levels = lists:duplicate(9, 500),
    ?assertEqual([492, 496, 495, 497, 495, 496, 497, 498, 498],
                 need:decay(Levels, need:default_decay())).

nothing_falls_below_the_floor_or_rises_above_the_ceiling_test() ->
    ?assertEqual(lists:duplicate(9, 0),
                 need:decay(lists:duplicate(9, 1), lists:duplicate(9, 50))),
    ?assertEqual(lists:duplicate(9, 1000),
                 need:apply_effect(lists:duplicate(9, 990), lists:duplicate(9, 50))).

%% ⚠ RULE 9 AS A TEST. There must be no total. `mean/1' answers with nine numbers
%% and the moment somebody adds a `welfare/1' that returns one, incommensurability
%% has been discarded and two cultures have become comparable on a scale neither
%% of them chose.
the_mean_is_nine_numbers_and_never_one_test() ->
    Vectors = [lists:duplicate(9, 400), lists:duplicate(9, 600)],
    ?assertEqual(lists:duplicate(9, 500), need:mean(Vectors)),
    ?assertEqual(9, length(need:mean(Vectors))),
    ?assertNot(erlang:function_exported(need, welfare, 1)),
    ?assertNot(erlang:function_exported(need, total, 1)).

%%==============================================================================
%% What a practice claims, and what it does
%%==============================================================================

a_practice_that_serves_only_its_own_axis_is_singular_test() ->
    S = satisfier:new(a, subsistence, [10, 0, 0, 0, 0, 0, 0, 0, 0]),
    ?assertEqual(singular, satisfier:classify(S)).

a_practice_that_serves_its_axis_and_another_is_synergic_test() ->
    S = satisfier:new(a, subsistence, [10, 5, 0, 0, 0, 0, 0, 0, 0]),
    ?assertEqual(synergic, satisfier:classify(S)).

a_practice_that_works_at_a_price_elsewhere_is_inhibiting_test() ->
    S = satisfier:new(a, subsistence, [10, -5, 0, 0, 0, 0, 0, 0, 0]),
    ?assertEqual(inhibiting, satisfier:classify(S)).

%% Claims an axis, does nothing to it, harms nothing. The false sense of
%% satisfaction: it simply does not work.
a_practice_that_does_not_do_what_it_says_is_pseudo_test() ->
    S = satisfier:new(a, subsistence, [0, 0, 0, 0, 0, 0, 0, 0, 0]),
    ?assertEqual(pseudo, satisfier:classify(S)).

%% ⚠ THE ONE THAT MATTERS. Claims an axis it does not serve AND damages another.
%% This is how a culture can be measurably bad for the persons carrying it
%% without anybody declaring from outside which cultures are bad.
a_practice_that_promises_and_damages_is_a_violator_test() ->
    S = satisfier:new(status_display, identity, [0, 0, -20, 0, 0, 0, 0, 0, 0]),
    ?assertEqual(violator, satisfier:classify(S)).

%% ⚠ ORDER IS THE DEFINITION. A practice that fails its own claim while raising
%% two other axes must NOT be called synergic: that is the sales pitch a violator
%% makes for itself, and classifying it generously would hide the only case worth
%% catching.
failing_your_own_claim_outranks_being_generous_elsewhere_test() ->
    S = satisfier:new(a, subsistence, [0, 20, 20, 0, 0, 0, 0, -1, 0]),
    ?assertEqual(violator, satisfier:classify(S)).

a_profile_of_the_wrong_width_is_refused_test() ->
    ?assertError({effect_wrong_width, a, 3, 9},
                 satisfier:new(a, subsistence, [1, 2, 3])).

%% Every class present even at zero, because a reader that must tell "no
%% violators" from "this island does not report violators" cannot, and a key that
%% appears only sometimes is a field a chart silently drops.
the_tally_names_every_class_even_at_zero_test() ->
    Tally = satisfier:tally(satisfier:catalogue()),
    ?assertEqual(lists:sort(satisfier:classes()), lists:sort(maps:keys(Tally))),
    ?assertEqual(0, maps:get(violator, Tally)),
    ?assertEqual(0, maps:get(pseudo, Tally)).

%% ⚠ THE STARTING CATALOGUE CONTAINS NO VIOLATORS ON PURPOSE. Seeding one would
%% put the interesting result in the initial conditions: a people damaged by their
%% own practices, arranged that way by whoever wrote the list. A violator has to
%% appear on its own or it means nothing.
the_starting_catalogue_is_nine_practices_that_work_test() ->
    Catalogue = satisfier:catalogue(),
    ?assertEqual(need:count(), length(Catalogue)),
    Classes = [satisfier:classify(S) || S <- Catalogue],
    %% ⚠ NOT `Classes -- [synergic, singular]'. The list subtraction operator
    %% removes ONE occurrence of each element, so nine classes minus a two-element
    %% list leaves seven and the assertion could never pass. The question is
    %% membership, and it has to be asked as membership.
    ?assert(lists:all(fun(C) -> lists:member(C, [synergic, singular]) end, Classes)).

every_axis_has_a_practice_that_claims_it_test() ->
    Claimed = lists:sort([satisfier:claims(S) || S <- satisfier:catalogue()]),
    ?assertEqual(lists:seq(1, need:count()), Claimed).

%%==============================================================================
%% A people, and one tick
%%==============================================================================

%% ⚠ Register `G.6': a run must be a pure function of its seed, or the fleet and
%% the laboratory are running different physics and nothing can see it.
the_same_seed_gives_the_same_island_test() ->
    A = island:run(island:new(small()), 200),
    B = island:run(island:new(small()), 200),
    ?assertEqual(island:people(A), island:people(B)),
    ?assertEqual(island:need_means(A), island:need_means(B)).

a_different_seed_gives_a_different_island_test() ->
    A = island:run(island:new(small()), 200),
    B = island:run(island:new((small())#{seed => 8}), 200),
    ?assertNotEqual(island:people(A), island:people(B)).

the_population_never_exceeds_capacity_test() ->
    I = island:run(island:new(small()), 500),
    ?assert(island:population(I) =< island:capacity(I)).

%% Everyone dies of age and is replaced, so a peaceful island still turns over.
%% That is load-bearing: if the only death were violent, "did a culture appear"
%% and "did violence appear" would be the same measurement.
a_peaceful_island_still_turns_over_test() ->
    I = island:run(island:new(small()), 200),
    ?assert(island:deaths(I) > 0),
    ?assert(island:births(I) > 0).

everybody_acts_every_tick_test() ->
    I = island:run(island:new(small()), 10),
    ?assert(island:acts(I) >= 10 * 30),
    ?assertEqual(10, island:tick_of(I)).

%% Needs move. Without this the whole vector is decoration.
needs_move_test() ->
    Start = island:need_means(island:new(small())),
    Later = island:need_means(island:run(island:new(small()), 100)),
    ?assertNotEqual(Start, Later),
    ?assertEqual(9, length(Later)).

%% ⚠ NOTHING DIES OF AN UNMET NEED YET, AND THAT IS DELIBERATE. Making one lethal
%% is adding a selection pressure, which rule 1 says must be priced against the
%% measured floor first. This test fails the day somebody wires it in, which is
%% the reminder to price it and write it down.
an_unmet_need_is_not_yet_fatal_test() ->
    Starved = island:run(island:new((small())#{crowding_bite => 500, capacity => 1}), 5),
    ?assert(hd(island:need_means(Starved)) < 50),
    %% The whole point: subsistence is on the floor and nobody has died of it.
    ?assert(island:population(Starved) > 30).

%% ⚠ AND AN OVER-CAPACITY PEOPLE SHRINKS UNTIL THE CROWDING STOPS, which I did
%% not think through when writing the first version of this suite and the model
%% did correctly. Deaths are not replaced above capacity, so the population falls
%% to it, crowding goes to zero, and the survivors recover.
%%
%% That is carrying capacity behaving as a material base rather than as a
%% punishment, and it is worth asserting as itself: it is the only pressure in
%% this model today, and if it ever stops self-limiting an island will grind its
%% people to zero on one axis for ever.
a_crowded_people_shrinks_until_it_stops_being_crowded_test() ->
    Crowded = island:new((small())#{crowding_bite => 500, capacity => 1}),
    Early = island:run(Crowded, 5),
    Late = island:run(Crowded, 60),
    ?assert(island:population(Late) < island:population(Early)),
    ?assert(island:population(Late) =< island:capacity(Late)),
    %% Crowding has stopped, so the axis it was falling on has recovered.
    ?assert(hd(island:need_means(Late)) > hd(island:need_means(Early))).

%% Crowding falls on the configured axis and on no other, which is rule 8 holding
%% at runtime rather than only in the documentation.
crowding_hits_one_axis_and_leaves_the_rest_alone_test() ->
    %% ⚠ ASSERTED ON THE DECAY RATES, NOT ON THE NEED MEANS. A first version
    %% compared the means of a crowded island against a roomy one and failed on
    %% the eight axes crowding never touches. It was right to fail: an
    %% over-capacity people also has fewer members, so every mean is taken over a
    %% different population and all nine differ for a reason that has nothing to
    %% do with crowding. Rule 8 is a claim about the rates, so the rates are what
    %% this looks at.
    Crowded = island:run(island:new((small())#{people => 50, capacity => 10}), 5),
    Roomy = island:run(island:new((small())#{people => 50, capacity => 200}), 5),
    Hit = need:index_of(subsistence),

    CrowdedRates = island:effective_decay(Crowded),
    RoomyRates = island:effective_decay(Roomy),

    ?assert(lists:nth(Hit, CrowdedRates) > lists:nth(Hit, RoomyRates)),
    ?assertEqual(drop(Hit, RoomyRates), drop(Hit, CrowdedRates)),
    %% And it does reach the axis: subsistence is on the floor while nothing else
    %% has moved far from where it started.
    ?assert(hd(island:need_means(Crowded)) < 50),
    ?assert(hd(island:need_means(Roomy)) > 400).

%% A roomy island has no crowding at all, so its rates are the plain defaults.
%% Without this, the test above would pass on a model that always crowds.
an_uncrowded_island_decays_at_the_plain_rates_test() ->
    Roomy = island:run(island:new((small())#{people => 10, capacity => 200}), 5),
    ?assertEqual(need:default_decay(), island:effective_decay(Roomy)).

drop(N, List) ->
    {Before, [_At | After]} = lists:split(N - 1, List),
    Before ++ After.
