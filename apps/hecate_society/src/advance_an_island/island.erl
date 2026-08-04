%% @doc A PEOPLE, AND ONE TICK OF THEIR LIVES. PURE.
%%
%% A person is an age and nine need levels. There is no position, because there
%% is no space inside an island in this design: an island is an undifferentiated
%% population and a coordinate would be a number that means nothing.
%%
%% ==========================================================================
%% WHAT A TICK DOES, IN ORDER
%% ==========================================================================
%%
%%   1. everyone ages, and whoever reached `lifespan' dies
%%   2. births replace the dead, up to carrying capacity
%%   3. every need falls by its own rate
%%   4. crowding falls on ONE configured axis, extra
%%   5. everyone acts: one satisfier each, chosen at random
%%
%% ⚠ **CHOSEN AT RANDOM, AND THAT IS THE NULL THIS EXISTS TO ESTABLISH.** Nothing
%% here decides anything: no belief, no network, no preference. A person picks a
%% practice out of the catalogue by chance. That is the baseline any later
%% mechanism has to beat, and building it first is what makes "the network chose
%% better" a measurable statement rather than an impression.
%%
%% ==========================================================================
%% DEATH IS BY AGE ALONE, AND UNMET NEEDS DO NOTHING YET
%% ==========================================================================
%%
%% `CHARTER.md' rules that a life is presence with a natural end, and that
%% natural mortality is load-bearing: if the only death were violent, "did a
%% culture appear" and "did violence appear" would be the same measurement.
%%
%% ⚠ NEEDS ARE MEASURED AND PUBLISHED AND NOTHING DEPENDS ON THEM. Making an
%% unmet need lethal would be adding a selection pressure, and rule 1 says a
%% mechanism is priced against the MEASURED drift floor before it is built. The
%% floor is measured (0.2% to 0.8%, see `design/RESEARCH_THE_MEASURED_FLOOR.md');
%% what an unmet need is worth is not. So it waits, and this comment is here so
%% nobody reads the silence as an oversight.
%%
%% ==========================================================================
%% A RUN IS A PURE FUNCTION OF ITS SEED, AND THAT IS ENFORCED HERE
%% ==========================================================================
%%
%% ⚠ Register `G.6': for seventeen worlds the predecessor's world was NOT a pure
%% function of its seed, because randomness was drawn while walking a map and
%% Erlang promises nothing about map order. The fleet and the laboratory ran
%% different physics and nothing could see it.
%%
%% So the population is a LIST, positions are walked in order, and the random
%% state is threaded explicitly. No map is iterated anywhere on the random path.
-module(island).

-export([new/1, defaults/0, tick/1, run/2]).
-export([people/1, population/1, tick_of/1, capacity/1, catalogue/1]).
-export([need_means/1, satisfier_tally/1, acts/1, deaths/1, births/1]).
-export([effective_decay/1]).

-type person() :: #{age := non_neg_integer(), needs := need:vector()}.
-type island() :: map().
-export_type([person/0, island/0]).

-spec defaults() -> map().
defaults() ->
    #{people => 100,
      capacity => 120,
      lifespan => 600,
      %% Which axis crowding falls on. AN INDEX, NOT A CLAUSE: rule 8 says no
      %% need may have code of its own, and being over capacity meaning "there is
      %% not enough to go round" is subsistence as data rather than a special
      %% case in the tick.
      crowding_hits => subsistence,
      crowding_bite => 6,
      seed => 101}.

-spec new(map()) -> island().
new(Opts0) ->
    Opts = maps:merge(defaults(), Opts0),
    #{people := N, seed := Seed} = Opts,
    Rand0 = rand:seed_s(exsss, {Seed, Seed bsr 3, Seed bsl 7}),
    {People, Rand} = founders(N, maps:get(lifespan, Opts), [], Rand0),
    #{tick => 0,
      people => People,
      capacity => maps:get(capacity, Opts),
      lifespan => maps:get(lifespan, Opts),
      decay => need:default_decay(),
      crowding_hits => need:index_of(maps:get(crowding_hits, Opts)),
      crowding_bite => maps:get(crowding_bite, Opts),
      catalogue => satisfier:catalogue(),
      acts => 0,
      deaths => 0,
      births => 0,
      rand => Rand}.

%% AGES ARE STAGGERED AT THE FOUNDING, or the whole people dies on one tick for
%% ever, which is a cohort model rather than the overlapping-generations one that
%% every `Ne' argument in this project rests on.
founders(0, _Lifespan, Acc, Rand) -> {lists:reverse(Acc), Rand};
founders(Left, Lifespan, Acc, Rand0) ->
    {Age, Rand1} = rand:uniform_s(Lifespan, Rand0),
    founders(Left - 1, Lifespan, [#{age => Age - 1, needs => need:fresh()} | Acc], Rand1).

-spec run(island(), non_neg_integer()) -> island().
run(I, 0) -> I;
run(I, Ticks) -> run(tick(I), Ticks - 1).

-spec tick(island()) -> island().
tick(I) -> act_round(fall(age_and_replace(I))).

%%==============================================================================
%% Death and birth
%%==============================================================================

age_and_replace(#{people := People, lifespan := Lifespan} = I) ->
    Aged = [P#{age := maps:get(age, P) + 1} || P <- People],
    Living = [P || P <- Aged, maps:get(age, P) < Lifespan],
    Died = length(Aged) - length(Living),
    born(Died, Living, I).

%% BIRTHS REPLACE THE DEAD UP TO CAPACITY AND NO FURTHER. Carrying capacity is
%% the whole material base in this design: one number, no resource field, no
%% metabolism. A people at capacity that loses somebody gains somebody; a people
%% over it does not.
born(Died, Living, #{capacity := Cap} = I) ->
    Room = max(0, Cap - length(Living)),
    Births = min(Died, Room),
    Newborns = lists:duplicate(Births, #{age => 0, needs => need:fresh()}),
    I#{people := Living ++ Newborns,
       deaths := maps:get(deaths, I) + Died,
       births := maps:get(births, I) + Births}.

%%==============================================================================
%% Needs fall
%%==============================================================================

%% ⚠ CROWDING FALLS ON ONE CONFIGURED AXIS, and the index comes from `defaults/0'
%% rather than from a clause. Being over capacity means there is not enough to go
%% round, which is subsistence, but writing `subsistence' into this function is
%% precisely the special case rule 8 forbids: the next axis to want one would get
%% it, and the hierarchy would be back.
fall(#{people := People} = I) ->
    Rates = effective_decay(I),
    I#{people := [P#{needs := need:decay(maps:get(needs, P), Rates)} || P <- People]}.

%% @doc The decay rates actually in force this tick, crowding included.
%%
%% ⚠ EXPORTED BECAUSE IT IS THE PHYSICS AND NOT AN INTERNAL. Comparing two
%% islands' need MEANS cannot tell you whether crowding touched one axis or
%% several: an over-capacity people also has fewer members, so every mean is
%% taken over a different population and all nine differ. That is what a first
%% version of this test asserted and it was measuring composition, not decay.
%%
%% Rule 8 is a claim about these numbers, so these numbers have to be visible.
-spec effective_decay(island()) -> need:vector().
effective_decay(#{people := People, decay := Decay} = I) ->
    Extra = crowding(length(People), maps:get(capacity, I), maps:get(crowding_bite, I)),
    bump_axis(Decay, maps:get(crowding_hits, I), Extra).

crowding(Population, Capacity, Bite) when Population > Capacity ->
    Bite * (Population - Capacity);
crowding(_Population, _Capacity, _Bite) ->
    0.

bump_axis(Rates, _Index, 0) -> Rates;
bump_axis(Rates, Index, Extra) ->
    {Before, [At | After]} = lists:split(Index - 1, Rates),
    Before ++ [At + Extra | After].

%%==============================================================================
%% Acting, which is where a belief will eventually go
%%==============================================================================

%% ⚠ THIS FUNCTION IS THE SEAM. Today it draws a practice uniformly at random,
%% which is the null. When a person has a network and a doctrine, WHICH practice
%% they reach for is what those decide, and nothing else in this module changes.
act_round(#{people := People, catalogue := Catalogue} = I) ->
    {Acted, Rand} = each(People, Catalogue, maps:get(rand, I), []),
    I#{people := Acted,
       rand := Rand,
       tick := maps:get(tick, I) + 1,
       acts := maps:get(acts, I) + length(Acted)}.

each([], _Catalogue, Rand, Acc) -> {lists:reverse(Acc), Rand};
each([P | Rest], Catalogue, Rand0, Acc) ->
    {Pick, Rand1} = rand:uniform_s(length(Catalogue), Rand0),
    Chosen = lists:nth(Pick, Catalogue),
    Needs = need:apply_effect(maps:get(needs, P), satisfier:effect(Chosen)),
    each(Rest, Catalogue, Rand1, [P#{needs := Needs} | Acc]).

%%==============================================================================
%% What a reader may ask
%%==============================================================================

-spec people(island()) -> [person()].
people(#{people := P}) -> P.

-spec population(island()) -> non_neg_integer().
population(#{people := P}) -> length(P).

-spec tick_of(island()) -> non_neg_integer().
tick_of(#{tick := T}) -> T.

-spec capacity(island()) -> pos_integer().
capacity(#{capacity := C}) -> C.

-spec catalogue(island()) -> [satisfier:satisfier()].
catalogue(#{catalogue := C}) -> C.

-spec acts(island()) -> non_neg_integer().
acts(#{acts := A}) -> A.

-spec deaths(island()) -> non_neg_integer().
deaths(#{deaths := D}) -> D.

-spec births(island()) -> non_neg_integer().
births(#{births := B}) -> B.

%% @doc The mean level on each of the nine axes.
%%
%% ⚠ NINE NUMBERS, NEVER ONE. Rule 9, and there is no function in this module
%% that returns an island's overall welfare, because this model does not contain
%% that quantity.
-spec need_means(island()) -> need:vector().
need_means(#{people := People}) ->
    need:mean([maps:get(needs, P) || P <- People]).

-spec satisfier_tally(island()) -> #{satisfier:class() => non_neg_integer()}.
satisfier_tally(#{catalogue := C}) -> satisfier:tally(C).
