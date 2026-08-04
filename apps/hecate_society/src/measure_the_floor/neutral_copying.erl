%% @doc A people who copy each other and believe nothing. PURE.
%%
%% ==========================================================================
%% THIS EXISTS TO FIND OUT WHETHER THE CHARTER IS REACHABLE
%% ==========================================================================
%%
%% `CHARTER.md' rule 1: a mechanism is chosen by its differential against the
%% MEASURED drift floor, before it is built. Nothing here has measured the floor.
%% The predecessor measured its own at world 22, found `Ne' 7.44 and a floor of
%% 6.72%, and discovered that nearly every mechanism it had ever priced was
%% invisible. That was twenty-two worlds too late.
%%
%% So this is the first thing built, before needs, before beliefs, before the
%% network. **If the floor here is as high as it was there, every ambitious thing
%% in the charter is unreachable and the charter is wrong rather than the code.**
%%
%% ==========================================================================
%% WHAT IT DELIBERATELY DOES NOT HAVE
%% ==========================================================================
%%
%% No needs, no satisfiers, no model, no doctrine, no network, no islands, no
%% migration, no violence. A person is an age, a standing, and one meaningless
%% label. Nothing here is a claim about culture.
%%
%% **That is the point.** Drift is what happens when NOTHING is selecting, so the
%% floor can only be measured in a world where nothing is. Adding any mechanism
%% would measure that mechanism instead.
%%
%% ==========================================================================
%% THE ONE THING WORTH SUSPECTING BEFORE THE RUN
%% ==========================================================================
%%
%% Under uniform copying, everybody is equally likely to be copied, so the number
%% of learners per teacher is roughly Poisson, variance tracks the mean, and `Ne'
%% should land near the census. If it does not, this model is wrong and the number
%% means nothing. **That is the sanity arm and it is not decoration.**
%%
%% ⚠ **Prestige bias is what should destroy it.** If learners prefer teachers who
%% appear to be doing well, a few teachers take most of the transmissions, the
%% variance in cultural fitness explodes, and `Ne' collapses. Prestige is a
%% mechanism the charter WANTS. So this run is asking whether the charter contains
%% something that destroys its own measurability, and how much of it is affordable.
%%
%% ⚠⚠ **STANDING IS DRAWN AT BIRTH AND IS UNCORRELATED WITH THE LABEL A PERSON
%% HOLDS.** That is what keeps this drift rather than selection. If who gets
%% copied depended on WHAT they believe, this would be measuring selection and
%% calling it a floor.
%%
%% ==========================================================================
%% A RUN IS A PURE FUNCTION OF ITS SEED, AND THAT IS ENFORCED HERE
%% ==========================================================================
%%
%% ⚠ The predecessor's register entry `G.6`: for seventeen worlds a world was NOT
%% a pure function of its seed, because two functions drew randomness while
%% walking a map, and Erlang promises nothing about map order. The fleet and the
%% laboratory were running different physics and nobody could see it.
%%
%% So the population here is a LIST and never a map, positions are walked in
%% order, and the random state is threaded explicitly. There is no map iteration
%% anywhere on the random path, by construction rather than by discipline.
-module(neutral_copying).

-export([new/1, defaults/0, run/2, tick/1]).
-export([labels/1, census/1, completed_teaching/1, transmissions/1, tick_of/1]).

-type person() :: #{age := non_neg_integer(),
                    standing := non_neg_integer(),
                    label := pos_integer(),
                    taught := non_neg_integer()}.
-type world() :: #{tick := non_neg_integer(),
                   n := pos_integer(),
                   lifespan := pos_integer(),
                   attention := pos_integer(),
                   adopt_pct := non_neg_integer(),
                   prestige_pct := non_neg_integer(),
                   persons := [person()],
                   transmissions := non_neg_integer(),
                   completed := [non_neg_integer()],
                   rand := rand:state()}.
-export_type([world/0, person/0]).

%% @doc Every constant, in one place, so a run can print what it ran.
%%
%% `adopt_pct' is the chance per person per tick of copying somebody. 20 means a
%% person revises a belief about every five ticks, so a life of 60 holds roughly
%% twelve revisions. `attention' is how many candidates are considered when they
%% do, which is the finite thing `DESIGN_ECONOMY_AND_SCARCITY.md' calls scarce.
-spec defaults() -> map().
defaults() ->
    #{n => 100,
      lifespan => 60,
      attention => 5,
      adopt_pct => 20,
      prestige_pct => 0,
      seed => 101}.

%% @doc A founding population, every person holding a label nobody else holds.
%%
%% ⚠ UNIQUE LABELS AND NO INNOVATION EVER. Diversity can only fall, which is what
%% makes its rate of fall readable as drift. A model with innovation reaches an
%% equilibrium instead, and an equilibrium tells you the mutation rate rather than
%% the effective size.
%%
%% AGES ARE STAGGERED AT THE FOUNDING. Everybody starting at zero would make the
%% whole people die on the same tick for ever, which is a cohort model and not an
%% overlapping-generations one, and the predecessor's own `Ne` work turned on
%% having overlapping generations.
-spec new(map()) -> world().
new(Opts0) ->
    Opts = maps:merge(defaults(), Opts0),
    #{n := N, lifespan := Lifespan, seed := Seed} = Opts,
    Rand0 = rand:seed_s(exsss, {Seed, Seed bsr 3, Seed bsl 7}),
    {Persons, Rand} = founders(N, Lifespan, 1, [], Rand0),
    #{tick => 0,
      n => N,
      lifespan => Lifespan,
      attention => maps:get(attention, Opts),
      adopt_pct => maps:get(adopt_pct, Opts),
      prestige_pct => maps:get(prestige_pct, Opts),
      persons => Persons,
      transmissions => 0,
      completed => [],
      rand => Rand}.

founders(0, _Lifespan, _Label, Acc, Rand) ->
    {lists:reverse(Acc), Rand};
founders(Left, Lifespan, Label, Acc, Rand0) ->
    {Age, Rand1} = rand:uniform_s(Lifespan, Rand0),
    {Standing, Rand2} = rand:uniform_s(100, Rand1),
    Person = #{age => Age - 1, standing => Standing - 1, label => Label, taught => 0},
    founders(Left - 1, Lifespan, Label + 1, [Person | Acc], Rand2).

-spec run(world(), non_neg_integer()) -> world().
run(W, 0) -> W;
run(W, Ticks) -> run(tick(W), Ticks - 1).

%% @doc One tick: the old die and are replaced, then everybody copies at once.
-spec tick(world()) -> world().
tick(W) -> copy_round(age_and_replace(W)).

%%==============================================================================
%% Death and birth, which keep the census flat
%%==============================================================================

%% THE CENSUS IS HELD CONSTANT ON PURPOSE. A population that grows or crashes
%% makes `Ne` a harmonic mean over a changing size, and the predecessor's worlds
%% crashed constantly, which is one of the three things it identified as
%% depressing `Ne`. Holding it flat isolates the one effect being measured here,
%% which is variance in who gets copied. Crashes come back as their own question.
age_and_replace(#{persons := Persons, lifespan := Lifespan} = W) ->
    Aged = [P#{age := maps:get(age, P) + 1} || P <- Persons],
    Indexed = lists:zip(lists:seq(1, length(Aged)), Aged),
    Dead = [Pos || {Pos, P} <- Indexed, maps:get(age, P) >= Lifespan],
    Living = [Pos || {Pos, P} <- Indexed, maps:get(age, P) < Lifespan],
    replace_dead(Dead, Living, Aged, W).

replace_dead([], _Living, Aged, W) ->
    W#{persons := Aged};
replace_dead(_Dead, [], Aged, W) ->
    %% Everybody died on the same tick, which the staggered founding is meant to
    %% prevent. Refusing rather than inventing a survivor to copy from: a silent
    %% recovery here would be a world nobody could reason about.
    error({whole_people_died_at_once, maps:get(tick, W), length(Aged)});
replace_dead(Dead, Living, Aged, #{completed := Done, rand := Rand0} = W) ->
    {Choices, Rand} = pick_parents(Dead, Living, Rand0, []),
    %% ⚠ THE PARENT IS CREDITED WITH THE TEACHING, and the first draft of this
    %% module forgot to. A newborn taking somebody's label makes that person a
    %% cultural parent exactly as an adoption does, and leaving the vertical
    %% channel uncounted would bias the variance estimator downward by however
    %% much of the transmission runs through birth. At a lifespan of 60 and a
    %% fifth of the people copying per tick that is about one event in thirteen,
    %% which is small and is still wrong.
    Credits = tally([Parent || {_Dead, Parent, _Standing} <- Choices]),
    Retired = [maps:get(taught, lists:nth(Pos, Aged)) || Pos <- Dead],
    Newborns = maps:from_list([newborn_entry(C, Aged) || C <- Choices]),
    Persons = [reborn_or_credited(Pos, P, Newborns, Credits)
               || {Pos, P} <- lists:zip(lists:seq(1, length(Aged)), Aged)],
    W#{persons := Persons, rand := Rand, completed := Retired ++ Done}.

%% ⚠ A NEWBORN TAKES A LABEL FROM A LIVING PERSON RATHER THAN A FRESH ONE. This is
%% the vertical channel, and without it the founding labels would simply die out
%% with their holders and diversity would fall for a reason that has nothing to do
%% with drift.
pick_parents([], _Living, Rand, Acc) ->
    {lists:reverse(Acc), Rand};
pick_parents([Pos | Rest], Living, Rand0, Acc) ->
    {Pick, Rand1} = rand:uniform_s(length(Living), Rand0),
    {Standing, Rand2} = rand:uniform_s(100, Rand1),
    pick_parents(Rest, Living, Rand2,
                 [{Pos, lists:nth(Pick, Living), Standing - 1} | Acc]).

newborn_entry({Pos, Parent, Standing}, Aged) ->
    {Pos, {maps:get(label, lists:nth(Parent, Aged)), Standing}}.

reborn_or_credited(Pos, P, Newborns, Credits) ->
    born(maps:find(Pos, Newborns), Pos, P, Credits).

born({ok, {Label, Standing}}, _Pos, _P, _Credits) ->
    #{age => 0, standing => Standing, label => Label, taught => 0};
born(error, Pos, P, Credits) ->
    P#{taught := maps:get(taught, P) + maps:get(Pos, Credits, 0)}.

%%==============================================================================
%% Copying, all at once
%%==============================================================================

%% ⚠ SIMULTANEOUS, NOT SEQUENTIAL. Everybody copies from the state at the START of
%% the tick. Sequential updating would make the answer depend on the order the
%% list happens to be in, which is the same class of fault as `G.6' even though
%% nothing here is a map: the first person to copy would be teaching the second
%% within the same tick.
copy_round(#{persons := Persons} = W) ->
    {Pairs, Rand} = choose_teachers(Persons, 1, W, [], maps:get(rand, W)),
    Applied = apply_pairs(Pairs, Persons),
    W#{persons := Applied,
       rand := Rand,
       tick := maps:get(tick, W) + 1,
       transmissions := maps:get(transmissions, W) + length(Pairs)}.

choose_teachers([], _Pos, _W, Pairs, Rand) ->
    {lists:reverse(Pairs), Rand};
choose_teachers([_P | Rest], Pos, W, Pairs, Rand0) ->
    {Roll, Rand1} = rand:uniform_s(100, Rand0),
    Copies = Roll =< maps:get(adopt_pct, W),
    maybe_choose(Copies, Rest, Pos, W, Pairs, Rand1).

maybe_choose(false, Rest, Pos, W, Pairs, Rand) ->
    choose_teachers(Rest, Pos + 1, W, Pairs, Rand);
maybe_choose(true, Rest, Pos, W, Pairs, Rand0) ->
    {Candidates, Rand1} = sample(maps:get(attention, W), maps:get(n, W), Pos,
                                 Rand0, []),
    {Teacher, Rand2} = weighted(Candidates, maps:get(persons, W),
                                maps:get(prestige_pct, W), Rand1),
    choose_teachers(Rest, Pos + 1, W, [{Pos, Teacher} | Pairs], Rand2).

%% WITH REPLACEMENT, AND SELF EXCLUDED. Sampling without replacement would need a
%% shuffle per person per tick and buys nothing at these sizes: a repeat simply
%% means the same candidate was considered twice, which is what limited attention
%% looks like anyway.
sample(0, _N, _Self, Rand, Acc) ->
    {Acc, Rand};
sample(Left, N, Self, Rand0, Acc) ->
    {Pick, Rand1} = rand:uniform_s(N, Rand0),
    retry_or_take(Pick =:= Self, Pick, Left, N, Self, Rand1, Acc).

retry_or_take(true, _Pick, Left, N, Self, Rand, Acc) ->
    sample(Left, N, Self, Rand, Acc);
retry_or_take(false, Pick, Left, N, Self, Rand, Acc) ->
    sample(Left - 1, N, Self, Rand, [Pick | Acc]).

%% @doc Which of the considered candidates is actually copied.
%%
%% At `prestige_pct' 0 every candidate weighs 1 and the choice is uniform, which
%% is the arm where `Ne' should land near the census. Above 0 a candidate's weight
%% rises with its standing, so a few people are copied by many.
%%
%% ⚠ STANDING IS INDEPENDENT OF THE LABEL. This produces variance in cultural
%% fitness WITHOUT producing selection on what is believed, which is the only way
%% the result is a drift floor rather than a selection coefficient.
weighted(Candidates, _Persons, 0, Rand0) ->
    {Pick, Rand1} = rand:uniform_s(length(Candidates), Rand0),
    {lists:nth(Pick, Candidates), Rand1};
weighted(Candidates, Persons, PrestigePct, Rand0) ->
    Weights = [{C, weight_of(C, Persons, PrestigePct)} || C <- Candidates],
    Total = lists:sum([Wt || {_C, Wt} <- Weights]),
    {Roll, Rand1} = rand:uniform_s(Total, Rand0),
    {walk(Weights, Roll), Rand1}.

weight_of(C, Persons, PrestigePct) ->
    100 + PrestigePct * maps:get(standing, lists:nth(C, Persons)).

walk([{C, _Wt}], _Left) -> C;
walk([{C, Wt} | Rest], Left) -> chosen(Left =< Wt, C, Rest, Left - Wt).

chosen(true, C, _Rest, _Left) -> C;
chosen(false, _C, Rest, Left) -> walk(Rest, Left).

apply_pairs(Pairs, Persons) ->
    Labels = [maps:get(label, P) || P <- Persons],
    Learned = maps:from_list([{L, lists:nth(T, Labels)} || {L, T} <- Pairs]),
    Taught = tally([T || {_L, T} <- Pairs]),
    [updated(Pos, P, Learned, Taught)
     || {Pos, P} <- lists:zip(lists:seq(1, length(Persons)), Persons)].

updated(Pos, P, Learned, Taught) ->
    P#{label := maps:get(Pos, Learned, maps:get(label, P)),
       taught := maps:get(taught, P) + maps:get(Pos, Taught, 0)}.

tally(Positions) -> lists:foldl(fun bump/2, #{}, Positions).

bump(Key, Acc) -> maps:update_with(Key, fun increment/1, 1, Acc).

increment(Count) -> Count + 1.

%%==============================================================================
%% What a reader may ask
%%==============================================================================

-spec labels(world()) -> [pos_integer()].
labels(#{persons := Persons}) -> [maps:get(label, P) || P <- Persons].

-spec census(world()) -> pos_integer().
census(#{n := N}) -> N.

%% @doc How many learners each DEAD person taught over a whole life.
%%
%% Completed lives only, because a person still living may yet teach somebody and
%% counting them would make the variance depend on when you looked. The
%% predecessor made the same distinction and its register entry `I.19' is about
%% getting it wrong: every gate there used a birth-weighted lifespan that
%% described newborns.
-spec completed_teaching(world()) -> [non_neg_integer()].
completed_teaching(#{completed := Done}) -> Done.

-spec transmissions(world()) -> non_neg_integer().
transmissions(#{transmissions := T}) -> T.

-spec tick_of(world()) -> non_neg_integer().
tick_of(#{tick := T}) -> T.
