%% @doc THE NINE AXES, AND NOT ONE OF THEM HAS CODE OF ITS OWN. PURE.
%%
%% `CHARTER.md' rule 8. A need is an index into a vector and nothing else. There
%% is no `subsistence/1', no clause that treats affection differently, and no
%% place where a tenth axis would need a function written for it.
%%
%% ⚠ THE MOMENT ONE NEED GETS A SPECIAL CASE, MASLOW'S HIERARCHY HAS ARRIVED
%% THROUGH THE IMPLEMENTATION. Max-Neef's central claim is that the nine are
%% simultaneous: no need is foundational and none is a luxury. A model that says
%% so in its documentation and then special-cases subsistence in its tick has
%% adopted the hierarchy while denying it.
%%
%% So everything here is vector arithmetic, and everything that differs between
%% axes is DATA: the decay rates are a vector, the crowding target is an index.
%% See `design/DESIGN_NEEDS_AND_SATISFIERS.md'.
%%
%% ==========================================================================
%% WHAT A LEVEL MEANS, AND WHAT IT DOES NOT
%% ==========================================================================
%%
%% Per-mille, 0 to 1000, because the wire rule is integers rather than floats and
%% a number that becomes a fact should be an integer from the start rather than a
%% float somebody remembers to round.
%%
%% ⚠⚠ **NOTHING DEPENDS ON A NEED YET, AND THAT IS DELIBERATE.** Levels move, are
%% measured and are published. Nobody dies of an unmet need and nobody chooses an
%% action because of one. What an unmet need DOES is a mechanism with a fitness
%% consequence, which is the kind of thing `CHARTER.md' rule 1 says must be priced
%% against the measured floor before it is built. Wiring it in now would smuggle
%% an unexamined selection pressure into the substrate.
%%
%% ⚠⚠⚠ AND THEY ARE NEVER SUMMED. Rule 9. Sen's incommensurability is a
%% commitment: the moment nine numbers become one, this model has a scalar
%% welfare and has thrown away the thing that makes two cultures different.
%% `mean/1' returns a VECTOR of nine means. There is no total and there will not
%% be one.
-module(need).

-export([axes/0, count/0, index_of/1, name_of/1]).
-export([fresh/0, decay/2, apply_effect/2, level/2, mean/1, clamp/1]).
-export([default_decay/0, floor_level/0, ceiling_level/0]).

-type level() :: 0..1000.
-type vector() :: [level()].
-export_type([level/0, vector/0]).

%% ⚠ WIRE ORDER. Appended to, never reordered. Every published need vector is
%% nine numbers in this order and a reader maps them by position, so swapping two
%% entries would silently relabel every measurement ever taken. `need_tests'
%% pins the list.
-define(AXES, [subsistence, protection, affection, understanding, participation,
               leisure, creation, identity, freedom]).

-define(FLOOR, 0).
-define(CEILING, 1000).

-spec axes() -> [atom()].
axes() -> ?AXES.

-spec count() -> pos_integer().
count() -> length(?AXES).

-spec floor_level() -> level().
floor_level() -> ?FLOOR.

-spec ceiling_level() -> level().
ceiling_level() -> ?CEILING.

%% @doc Which position an axis occupies, one-based. Crashes on an unknown name,
%% because a typo in a satisfier's claim should fail at the seed rather than
%% quietly claim to serve axis zero.
-spec index_of(atom()) -> pos_integer().
index_of(Axis) -> located(index_search(?AXES, Axis, 1), Axis).

index_search([Axis | _Rest], Axis, N) -> N;
index_search([_Other | Rest], Axis, N) -> index_search(Rest, Axis, N + 1);
index_search([], _Axis, _N) -> not_an_axis.

located(not_an_axis, Axis) -> error({not_an_axis, Axis});
located(N, _Axis) -> N.

-spec name_of(pos_integer()) -> atom().
name_of(N) when N >= 1, N =< length(?AXES) -> lists:nth(N, ?AXES).

%% @doc A person's needs at birth: half met on every axis.
%%
%% Uniform on purpose. A founding population weighted toward one axis would be a
%% culture that nobody chose, handed over before anything could evolve one.
-spec fresh() -> vector().
fresh() -> lists:duplicate(count(), ?CEILING div 2).

%% @doc How fast each axis falls when nothing is done about it.
%%
%% A VECTOR RATHER THAN A CONSTANT, and that is the whole of rule 8 in practice.
%% Hunger returning faster than a need for meaning is a real asymmetry, and it
%% belongs in data where a tenth axis costs one more number, not in a clause.
%%
%% These are a starting point and not a finding. Nothing has been swept, because
%% nothing yet depends on a need, so there is no outcome to sweep against and
%% tuning them now would be tuning for a picture. Recorded in the register when
%% the first mechanism reads them.
-spec default_decay() -> vector().
default_decay() -> [8, 4, 5, 3, 5, 4, 3, 2, 2].

%% @doc One tick of going unmet.
-spec decay(vector(), vector()) -> vector().
decay(Levels, Rates) ->
    [clamp(L - R) || {L, R} <- lists:zip(Levels, Rates)].

%% @doc Apply a satisfier's effect profile.
%%
%% Straight vector addition, clamped at both ends. A satisfier that lowers an axis
%% is doing exactly what Max-Neef's inhibitors and violators do, so this must not
%% refuse a negative delta.
-spec apply_effect(vector(), [integer()]) -> vector().
apply_effect(Levels, Effect) ->
    [clamp(L + D) || {L, D} <- lists:zip(Levels, Effect)].

-spec level(vector(), pos_integer()) -> level().
level(Levels, Index) -> lists:nth(Index, Levels).

%% @doc The mean level on each axis across a population.
%%
%% ⚠ RETURNS NINE NUMBERS AND NEVER ONE. Rule 9. There is no function here that
%% returns a person's or a people's overall welfare, because this model does not
%% contain that quantity: a culture is a set of satisfiers and the axes are
%% incommensurable, so no weighting exists that is not somebody's culture.
-spec mean([vector()]) -> vector().
mean([]) -> lists:duplicate(count(), 0);
mean(Vectors) ->
    N = length(Vectors),
    Totals = lists:foldl(fun add/2, lists:duplicate(count(), 0), Vectors),
    [T div N || T <- Totals].

add(V, Acc) -> [A + B || {A, B} <- lists:zip(Acc, V)].

-spec clamp(integer()) -> level().
clamp(V) when V < ?FLOOR -> ?FLOOR;
clamp(V) when V > ?CEILING -> ?CEILING;
clamp(V) -> V.
