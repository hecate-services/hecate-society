%% @doc How many people are actually deciding what this world believes. PURE.
%%
%% ==========================================================================
%% TWO ESTIMATORS, BECAUSE ONE NUMBER FROM ONE METHOD IS A GUESS WITH ARITHMETIC
%% ==========================================================================
%%
%% Carried from the predecessor, which reported both and said out loud that one
%% of them had its assumption broken. That honesty is the reason its `Ne' number
%% was usable at all.
%%
%%   `from_decay/2'     THE ONE TO READ. Diversity can only fall in a world with
%%                      no innovation, and under drift alone it falls at a rate
%%                      set by the effective size. Fits that rate. Makes no
%%                      assumption about generations being discrete, which is
%%                      what broke the other one.
%%
%%   `from_variance/2'  Crow and Kimura, from the spread in how many learners
%%                      each person taught. **It assumes discrete
%%                      non-overlapping generations: everybody teaches, then
%%                      everybody dies.** This world has neither. It is here for
%%                      its INPUTS, the mean and the variance, which are measured
%%                      and real and say plainly whether transmission is
%%                      concentrated.
%%
%% ==========================================================================
%% WHAT THE ANSWER IS FOR
%% ==========================================================================
%%
%% The drift floor is `1 / (2·Ne)'. A mechanism whose advantage is smaller than
%% that is moved by chance rather than by selection, and measuring it is measuring
%% noise. `CHARTER.md' rule 1 turns that into a gate that runs BEFORE anything is
%% built, and rule 2 makes a run below the floor declare itself invalid.
%%
%% The predecessor's floor was 6.72%. Its mechanisms were priced at 0.24%, 1.34%
%% and 10.6%. Two of the three were invisible and nobody knew for twenty-two
%% worlds.
-module(effective_size).

-export([diversity_ppm/1, from_decay/2, from_variance/2, floor_ppm/1]).

%% @doc The chance that two people picked at random hold different labels.
%%
%% Reported in parts per million as an integer. The wire rule about integers is
%% about facts leaving this system, and this number is on its way to becoming
%% one, so it is an integer from the start rather than a float that gets rounded
%% at the last moment by whoever remembers.
-spec diversity_ppm([term()]) -> non_neg_integer().
diversity_ppm([]) -> 0;
diversity_ppm(Labels) ->
    N = length(Labels),
    Counts = maps:values(tally(Labels)),
    SumSquares = lists:sum([C * C || C <- Counts]),
    %% 1 - sum(p^2), in ppm, with the division done once at the end so integer
    %% arithmetic carries the precision rather than losing it per term.
    max(0, 1000000 - (SumSquares * 1000000) div (N * N)).

%% @doc `Ne' from how fast diversity falls, which is the estimate to believe.
%%
%% Takes samples of `{GenerationsElapsed, DiversityPpm}' and fits
%% `ln H = ln H0 + b·g' by least squares. Under drift in a haploid population,
%% `H' falls by a factor of `(1 - 1/Ne)' per generation, so `b = ln(1 - 1/Ne)'
%% and `Ne = 1 / (1 - e^b)'.
%%
%% ⚠ **A GENERATION IS COUNTED IN REPLACEMENT EVENTS, NOT IN TICKS.** One
%% generation is `N' label replacements, counting births and adoptions together,
%% so the answer does not depend on how often anybody happens to copy. Ticks would
%% make `Ne' move when the copying rate moved, which would be measuring the
%% copying rate.
%%
%% ⚠⚠ **SAMPLES WHERE DIVERSITY HAS ALREADY COLLAPSED ARE DROPPED.** Once one
%% label has fixed, `H' is zero, its logarithm is undefined, and the tail would
%% otherwise drag the fit toward whatever the last few points did. Fewer than
%% three usable points is `insufficient' rather than a number.
-spec from_decay([{number(), non_neg_integer()}], pos_integer()) ->
          {ok, float()} | {error, atom()}.
%% ⚠⚠⚠ AND THE DEEP TAIL IS DROPPED TOO, WHICH THE FIRST VERSION DID NOT DO AND
%% WAS WRONG FOR.
%%
%% Once diversity has fallen to a few percent of where it started, what is left is
%% a handful of copies of one or two labels, and every further step is dominated
%% by whether one lineage happened to win. Those points are still positive, so
%% they survived the `H > 0' filter, and a least-squares line weights them exactly
%% as heavily as the clean early decay.
%%
%% **The symptom was a census of 400 reporting an effective size of 243 while a
%% census of 100 reported 101.** Nothing about the model differed. What differed
%% is that the smaller run fixed early, so its noisy tail was already excluded by
%% being zero, while the larger run's tail was small but non-zero and dragged the
%% slope. An estimator whose answer depends on how much of the tail happens to be
%% exactly zero is not measuring the population.
%%
%% So the fit runs from the start down to a twentieth of the starting diversity.
%% That is a stated window rather than a tuned one: it is the range in which the
%% exponential approximation is what the arithmetic is about.
from_decay(Samples, _N) ->
    Usable = in_window(Samples),
    fitted(length(Usable) >= 3, Usable).

in_window([]) -> [];
in_window([{_G, H0} | _] = Samples) ->
    Cutoff = max(1000, H0 div 20),
    [{G, math:log(H / 1000000)} || {G, H} <- Samples, H >= Cutoff].

fitted(false, _Usable) -> {error, insufficient};
fitted(true, Usable) -> slope_to_ne(slope(Usable)).

%% A slope of zero or above means diversity did not fall, so nothing drifted and
%% no effective size can be read off it. That is a real outcome for a short run
%% and it is reported rather than turned into an enormous number.
slope_to_ne(B) when B >= -1.0e-12 -> {error, no_decay};
slope_to_ne(B) -> {ok, 1.0 / (1.0 - math:exp(B))}.

slope(Points) ->
    N = length(Points),
    SumX = lists:sum([X || {X, _Y} <- Points]),
    SumY = lists:sum([Y || {_X, Y} <- Points]),
    SumXY = lists:sum([X * Y || {X, Y} <- Points]),
    SumXX = lists:sum([X * X || {X, _Y} <- Points]),
    Denominator = N * SumXX - SumX * SumX,
    safe_slope(Denominator, N * SumXY - SumX * SumY, Denominator).

safe_slope(0, _Numerator, _D) -> 0.0;
safe_slope(_NonZero, Numerator, D) -> Numerator / D.

%% @doc `Ne' from the spread in how many learners each person taught.
%%
%% ⚠ **REPORTED WITH ITS ASSUMPTION BROKEN, WHICH IS SAID HERE RATHER THAN
%% DISCOVERED BY A READER.** Crow and Kimura assume discrete non-overlapping
%% generations. This world has overlapping ones, so the number is indicative and
%% the mean and variance beside it are the part to trust.
%%
%% Returns the mean and the variance as well, both scaled by a thousand so they
%% stay integers, because **the variance-to-mean ratio is the actual finding**:
%% at one, transmission is spread evenly and `Ne' tracks the census; far above
%% one, a few teachers hold the whole future.
-spec from_variance([non_neg_integer()], pos_integer()) -> map().
from_variance([], N) ->
    #{ne => 0.0, mean_milli => 0, variance_milli => 0, ratio_milli => 0, n => N,
       lives => 0};
from_variance(Taught, N) ->
    Lives = length(Taught),
    Mean = lists:sum(Taught) / Lives,
    Variance = lists:sum([(K - Mean) * (K - Mean) || K <- Taught]) / Lives,
    #{ne => crow_kimura(N, Mean, Variance),
      mean_milli => round(Mean * 1000),
      variance_milli => round(Variance * 1000),
      ratio_milli => ratio_milli(Mean, Variance),
      n => N,
      lives => Lives}.

ratio_milli(Mean, _Variance) when Mean =< 0.0 -> 0;
ratio_milli(Mean, Variance) -> round((Variance / Mean) * 1000).

crow_kimura(_N, Mean, _Variance) when Mean =< 0.0 -> 0.0;
crow_kimura(N, Mean, Variance) ->
    Denominator = Mean - 1.0 + Variance / Mean,
    kimura(Denominator, N, Mean).

kimura(D, _N, _Mean) when abs(D) < 1.0e-9 -> 0.0;
kimura(D, N, Mean) -> (N * Mean - 1.0) / D.

%% @doc The smallest advantage this world could tell apart from chance.
%%
%% `1 / (2·Ne)', in parts per million, so it can sit beside a mechanism's priced
%% differential and be compared without anybody converting units in their head.
%% That conversion is where the predecessor's gates went wrong: they compared a
%% percentage against a floor nobody had measured.
-spec floor_ppm(number()) -> non_neg_integer().
floor_ppm(Ne) when Ne =< 0 -> 1000000;
floor_ppm(Ne) -> min(1000000, round(1000000 / (2 * Ne))).

tally(Items) -> lists:foldl(fun bump/2, #{}, Items).

bump(Key, Acc) -> maps:update_with(Key, fun increment/1, 1, Acc).

increment(Count) -> Count + 1.
