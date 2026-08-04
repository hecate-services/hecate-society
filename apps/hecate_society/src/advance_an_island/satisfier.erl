%% @doc WHAT A PEOPLE ACTUALLY DOES ABOUT A NEED, AND WHETHER IT WORKS. PURE.
%%
%% ==========================================================================
%% A CULTURE IS A SET OF SATISFIERS
%% ==========================================================================
%%
%% Max-Neef's central claim: the nine needs are the same in every culture and
%% every historical period, and what varies is the MEANS by which they are met.
%% That is give-the-plan-evolve-the-parameters, formalised by an economist in
%% 1986, and it is why a culture here is not a weighting over the axes. A
%% weighting is a number. A satisfier is a practice, and a practice can be
%% taught, argued over, imposed and abandoned.
%%
%% See `design/DESIGN_NEEDS_AND_SATISFIERS.md'.
%%
%% ==========================================================================
%% A SATISFIER CLAIMS ONE THING AND DOES ANOTHER, AND THE GAP IS MEASURABLE
%% ==========================================================================
%%
%% Two parts, and keeping them apart is the entire point:
%%
%%   `claims'  which need this practice is FOR. One axis.
%%   `effect'  what it actually does to all nine.
%%
%% **That gap is how a culture can be measurably bad for the persons carrying it
%% without anybody declaring from outside which cultures are bad.** A practice
%% that claims to serve identity while destroying affection is a violator, and
%% violator is a MEASUREMENT rather than a judgement: it compares what was
%% promised against what the need vector did.
%%
%% ⚠ A CLAIM IS NOT A BELIEF AND THIS IS NOT THE DOCTRINE. A claim is what a
%% practice is understood to be for. Doctrine, when it exists, will be what one
%% person told another, and the two will be able to disagree. They are separate
%% and this module knows nothing about the second.
-module(satisfier).

-export([new/3, catalogue/0, name/1, claims/1, effect/1]).
-export([classify/1, classes/0, tally/1]).

-type satisfier() :: #{name := atom(),
                       claims := pos_integer(),
                       effect := [integer()]}.
-type class() :: synergic | singular | inhibiting | pseudo | violator.
-export_type([satisfier/0, class/0]).

%% @doc A practice: what it is called, which axis it is for, what it does.
%%
%% The effect must be exactly as wide as the need vector. A short profile would
%% silently leave the last axes untouched, which reads as "this practice does not
%% affect freedom" when what happened is that somebody miscounted.
-spec new(atom(), atom(), [integer()]) -> satisfier().
new(Name, ClaimsAxis, Effect) when is_atom(Name), is_list(Effect) ->
    Width = need:count(),
    checked(length(Effect) =:= Width, Name, ClaimsAxis, Effect, Width).

checked(false, Name, _Axis, Effect, Width) ->
    error({effect_wrong_width, Name, length(Effect), Width});
checked(true, Name, Axis, Effect, _Width) ->
    #{name => Name, claims => need:index_of(Axis), effect => Effect}.

-spec name(satisfier()) -> atom().
name(#{name := N}) -> N.

-spec claims(satisfier()) -> pos_integer().
claims(#{claims := C}) -> C.

-spec effect(satisfier()) -> [integer()].
effect(#{effect := E}) -> E.

%%==============================================================================
%% The classification, which is Max-Neef's and is computed rather than declared
%%==============================================================================

%% @doc Which kind of satisfier this is, from its own numbers.
%%
%% Max-Neef names five and each is decidable from the claim and the effect:
%%
%%   `violator'    claims an axis it does not serve, and damages another. The
%%                 practice that promises identity and costs you affection.
%%   `pseudo'      claims an axis it does not serve, and damages nothing. It
%%                 simply does not work, which is the false sense of
%%                 satisfaction.
%%   `inhibiting'  serves its axis and damages another. It works, at a price
%%                 paid somewhere the claim does not mention.
%%   `synergic'    serves its axis and others with it, damaging none.
%%   `singular'    serves its axis, exactly, and nothing else.
%%
%% ⚠ THE ORDER OF THESE CLAUSES IS THE DEFINITION AND NOT AN OPTIMISATION.
%% Whether the claim is honoured is asked FIRST, because a practice that does not
%% do what it says is the interesting case however generous it is elsewhere. A
%% version that checked synergy first would classify a practice that fails its
%% own claim while raising two other axes as `synergic', which is exactly the
%% sales pitch a violator makes for itself.
-spec classify(satisfier()) -> class().
classify(#{claims := Index, effect := Effect}) ->
    OnClaim = lists:nth(Index, Effect),
    Others = drop_nth(Index, Effect),
    judge(OnClaim > 0, lists:any(fun(D) -> D < 0 end, Others),
          lists:any(fun(D) -> D > 0 end, Others)).

judge(false, true, _Up) -> violator;
judge(false, false, _Up) -> pseudo;
judge(true, true, _Up) -> inhibiting;
judge(true, false, true) -> synergic;
judge(true, false, false) -> singular.

-spec classes() -> [class()].
classes() -> [synergic, singular, inhibiting, pseudo, violator].

%% @doc How many of each kind are in use, as a map with every class present.
%%
%% ⚠ EVERY CLASS IS PRESENT EVEN AT ZERO, because this becomes a published fact
%% and a reader that has to distinguish "no violators" from "this island does not
%% report violators" cannot. A key that appears only sometimes is a field that a
%% chart silently drops.
-spec tally([satisfier()]) -> #{class() => non_neg_integer()}.
tally(Satisfiers) ->
    Empty = maps:from_list([{C, 0} || C <- classes()]),
    lists:foldl(fun bump/2, Empty, [classify(S) || S <- Satisfiers]).

bump(Class, Acc) -> maps:update_with(Class, fun increment/1, 1, Acc).

increment(N) -> N + 1.

drop_nth(N, List) ->
    {Before, [_At | After]} = lists:split(N - 1, List),
    Before ++ After.

%%==============================================================================
%% The starting catalogue
%%==============================================================================

%% @doc The practices an island begins with, one honest one per axis.
%%
%% ⚠ GIVEN, AND SAID OUT LOUD TO BE SCAFFOLDING. `CHARTER.md' rule 4: give the
%% plan, evolve the parameters. What must EMERGE is which satisfiers a people
%% arrives at, and nothing here evolves yet, so this is a handed-over starting
%% set and not a finding.
%%
%% ⚠⚠ AND IT CONTAINS NO VIOLATORS ON PURPOSE. Seeding one would put the
%% interesting result in the initial conditions: an island whose people are
%% damaged by their own practices, arranged that way by whoever wrote this list.
%% A violator has to appear on its own or it means nothing, and until something
%% can invent a practice the honest catalogue is nine that work.
%%
%% The numbers are a starting point rather than a measurement. Nothing has been
%% swept, because nothing yet depends on a need.
-spec catalogue() -> [satisfier()].
catalogue() ->
    [new(Name, Axis, profile(Axis, Gain, With))
     || {Name, Axis, Gain, With} <- starting_set()].

starting_set() ->
    [{foraging, subsistence, 40, []},
     {shelter_building, protection, 30, [subsistence]},
     {companionship, affection, 30, [participation]},
     {watching_the_world, understanding, 25, []},
     {gathering, participation, 25, [affection]},
     {resting, leisure, 30, [protection]},
     {making_things, creation, 25, [identity]},
     {telling_who_we_are, identity, 20, [participation]},
     {going_where_you_like, freedom, 20, []}].

%% Builds a nine-wide profile: the claimed axis gains `Gain', each axis in `With'
%% gains half of it, everything else is untouched. Half rather than a second
%% number because a synergic practice serving its neighbour AS WELL as its claim
%% is the shape being modelled, and two tunable numbers per practice would be
%% eighteen constants nobody has measured.
profile(Axis, Gain, With) ->
    Claimed = need:index_of(Axis),
    Side = [need:index_of(A) || A <- With],
    [delta(N, Claimed, Side, Gain) || N <- lists:seq(1, need:count())].

delta(N, N, _Side, Gain) -> Gain;
delta(N, _Claimed, Side, Gain) -> side_delta(lists:member(N, Side), Gain).

side_delta(true, Gain) -> Gain div 2;
side_delta(false, _Gain) -> 0.
