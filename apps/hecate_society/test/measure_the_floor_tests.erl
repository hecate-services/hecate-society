%% @doc The floor, and the model it is measured in.
%%
%% ⚠ THE SANITY ARM IS THE POINT OF THIS SUITE. Under uniform copying everybody is
%% equally likely to be copied, so the number of learners per teacher is roughly
%% Poisson, its variance tracks its mean, and `Ne' should land near the census. If
%% that does not hold, the model is wrong and every number it produces is a number
%% about a bug.
-module(measure_the_floor_tests).

-include_lib("eunit/include/eunit.hrl").

small() -> #{n => 60, lifespan => 40, attention => 5, adopt_pct => 20,
             prestige_pct => 0, seed => 7}.

%%==============================================================================
%% A run is a pure function of its seed
%%==============================================================================

%% ⚠ THE PREDECESSOR'S `G.6': for seventeen worlds a world was NOT a pure function
%% of its seed, because randomness was drawn while walking a map and Erlang
%% promises nothing about map order. The fleet and the laboratory ran different
%% physics and nothing could see it. This is the guard that would have.
the_same_seed_gives_the_same_world_test() ->
    A = neutral_copying:run(neutral_copying:new(small()), 200),
    B = neutral_copying:run(neutral_copying:new(small()), 200),
    ?assertEqual(neutral_copying:labels(A), neutral_copying:labels(B)),
    ?assertEqual(neutral_copying:completed_teaching(A),
                 neutral_copying:completed_teaching(B)).

a_different_seed_gives_a_different_world_test() ->
    A = neutral_copying:run(neutral_copying:new(small()), 200),
    B = neutral_copying:run(neutral_copying:new((small())#{seed => 8}), 200),
    ?assertNotEqual(neutral_copying:labels(A), neutral_copying:labels(B)).

%%==============================================================================
%% The world holds together
%%==============================================================================

the_census_never_moves_test() ->
    W = neutral_copying:new(small()),
    Sizes = [length(neutral_copying:labels(neutral_copying:run(W, T)))
             || T <- [0, 1, 50, 200]],
    ?assertEqual([60, 60, 60, 60], Sizes).

%% ⚠ THIS TEST ORIGINALLY ASSERTED THAT DIVERSITY ONLY EVER FALLS, AND IT FAILED,
%% AND THE TEST WAS WRONG RATHER THAN THE MODEL.
%%
%% No innovation exists, so what can never rise is the NUMBER OF DISTINCT LABELS:
%% a label that is lost is lost for ever. But diversity is `1 - sum(p^2)', and
%% that is a function of how EVEN the frequencies are, which fluctuates in both
%% directions in a finite population. Sixty people holding 59 and 1 have less of
%% it than the same sixty holding 58 and 2, so the rare label drifting up raises
%% diversity while the number of labels has not changed at all.
%%
%% **Drift lowers diversity in expectation, not in realisation.** An invariant
%% that only holds in expectation is not an invariant, and asserting it as one
%% produces a red test that looks like a broken model. Register `I.24'.
the_number_of_beliefs_only_ever_falls_test() ->
    W0 = neutral_copying:new(small()),
    Series = sampled(W0, 40, 10, fun distinct/1, []),
    Pairs = lists:zip(lists:droplast(Series), tl(Series)),
    ?assert(lists:all(fun({Earlier, Later}) -> Later =< Earlier end, Pairs)).

%% What IS true of diversity is the long-run statement, and it is the one the
%% decay fit actually rests on.
diversity_falls_a_long_way_over_a_long_run_test() ->
    W0 = neutral_copying:new(small()),
    Start = effective_size:diversity_ppm(neutral_copying:labels(W0)),
    Later = effective_size:diversity_ppm(
              neutral_copying:labels(neutral_copying:run(W0, 3000))),
    ?assert(Later < Start div 2).

distinct(W) -> length(lists:usort(neutral_copying:labels(W))).

sampled(_W, 0, _Every, _F, Acc) -> lists:reverse(Acc);
sampled(W, Left, Every, F, Acc) ->
    sampled(neutral_copying:run(W, Every), Left - 1, Every, F, [F(W) | Acc]).

%% Every person starts with a label nobody else holds, so at the founding two
%% people picked at random almost never match.
a_founding_people_all_believe_different_things_test() ->
    W = neutral_copying:new(small()),
    ?assert(effective_size:diversity_ppm(neutral_copying:labels(W)) > 980000).

everybody_teaches_somebody_or_nobody_but_the_books_balance_test() ->
    W = neutral_copying:run(neutral_copying:new(small()), 400),
    Taught = neutral_copying:completed_teaching(W),
    ?assert(length(Taught) > 0),
    ?assert(lists:all(fun(K) -> K >= 0 end, Taught)).

%%==============================================================================
%% The sanity arm, and the arm that should break it
%%==============================================================================

%% ⚠ UNIFORM COPYING SHOULD GIVE A VARIANCE THAT TRACKS ITS MEAN. That is the
%% Poisson signature of everybody being equally likely to be copied. A ratio far
%% from one here means the model is concentrating transmission for some reason
%% nobody asked for, and every `Ne' it reports afterwards would be wrong.
uniform_copying_spreads_teaching_evenly_test() ->
    W = neutral_copying:run(neutral_copying:new(small()), 1200),
    #{ratio_milli := Ratio} = effective_size:from_variance(
                                neutral_copying:completed_teaching(W), 60),
    ?assert(Ratio > 500),
    ?assert(Ratio < 2500).

%% ⚠ AND PRESTIGE SHOULD DESTROY THAT, which is the whole question this experiment
%% exists to ask. If learners prefer teachers who appear to be doing well, a few
%% teachers take most of the transmissions and the variance runs away from the
%% mean. This test asserts the mechanism BITES; how badly is what the sweep
%% measures.
prestige_concentrates_teaching_on_a_few_test() ->
    Flat = neutral_copying:run(neutral_copying:new(small()), 1200),
    Steep = neutral_copying:run(
              neutral_copying:new((small())#{prestige_pct => 100}), 1200),
    #{ratio_milli := FlatRatio} =
        effective_size:from_variance(neutral_copying:completed_teaching(Flat), 60),
    #{ratio_milli := SteepRatio} =
        effective_size:from_variance(neutral_copying:completed_teaching(Steep), 60),
    ?assert(SteepRatio > FlatRatio).

%%==============================================================================
%% The estimators, against arithmetic rather than against a simulation
%%==============================================================================

diversity_of_one_belief_held_by_everybody_is_zero_test() ->
    ?assertEqual(0, effective_size:diversity_ppm([a, a, a, a])).

diversity_of_an_even_split_is_a_half_test() ->
    ?assertEqual(500000, effective_size:diversity_ppm([a, a, b, b])).

diversity_of_nobody_is_zero_test() ->
    ?assertEqual(0, effective_size:diversity_ppm([])).

%% Synthetic decay at a known effective size, so the fit is checked against
%% arithmetic rather than against another guess. Recovering 50 from data generated
%% at 50 is the only way to know the estimator is not measuring itself.
the_decay_fit_recovers_an_effective_size_it_was_given_test() ->
    Ne = 50.0,
    Samples = [{G, round(1000000 * math:pow(1 - 1 / Ne, G))} || G <- lists:seq(0, 40)],
    {ok, Estimate} = effective_size:from_decay(Samples, 100),
    ?assert(abs(Estimate - Ne) < 2.0).

the_decay_fit_recovers_a_small_effective_size_too_test() ->
    Ne = 8.0,
    Samples = [{G, round(1000000 * math:pow(1 - 1 / Ne, G))} || G <- lists:seq(0, 20)],
    {ok, Estimate} = effective_size:from_decay(Samples, 100),
    ?assert(abs(Estimate - Ne) < 1.0).

%% Three points is the least a line can be fitted through honestly. Fewer says so
%% rather than returning a number, because a number from two points is a slope
%% with no evidence that it is a trend.
too_few_samples_refuses_rather_than_guesses_test() ->
    ?assertEqual({error, insufficient},
                 effective_size:from_decay([{0, 1000000}, {1, 990000}], 100)).

%% A run too short to have lost any diversity has not drifted, and saying so is
%% better than dividing by something near zero and reporting an enormous
%% population.
a_world_that_did_not_drift_says_so_test() ->
    Flat = [{G, 1000000} || G <- lists:seq(0, 10)],
    ?assertEqual({error, no_decay}, effective_size:from_decay(Flat, 100)).

%%==============================================================================
%% The floor
%%==============================================================================

%% The predecessor's own number, as a fixed point: `Ne' 7.44 gave a floor of
%% 6.72%. If this arithmetic ever disagrees with that, one of the two is wrong and
%% it is worth knowing which.
the_predecessors_floor_comes_out_where_it_did_test() ->
    ?assertEqual(67204, effective_size:floor_ppm(7.44)).

a_larger_population_can_see_smaller_things_test() ->
    ?assert(effective_size:floor_ppm(500) < effective_size:floor_ppm(50)),
    ?assertEqual(1000, effective_size:floor_ppm(500)).

%% A mechanism worth 1% needs an effective size above 50 before it is anything but
%% noise. That single sentence is why this experiment is built before the needs,
%% the beliefs and the network.
one_percent_needs_fifty_test() ->
    ?assert(effective_size:floor_ppm(50) =< 10000),
    ?assert(effective_size:floor_ppm(49) > 10000).
