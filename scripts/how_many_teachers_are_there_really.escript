#!/usr/bin/env escript
%%! -pa _build/default/lib/hecate_society/ebin
%% @doc `Ne': HOW MANY PEOPLE ARE ACTUALLY DECIDING WHAT THIS WORLD BELIEVES?
%%
%% Usage:  ./scripts/how_many_teachers_are_there_really.escript [seeds [ticks]]
%%
%% ==========================================================================
%% THIS IS THE FIRST THING BUILT, AND IT IS BUILT TO INVALIDATE THE CHARTER
%% ==========================================================================
%%
%% `CHARTER.md' rule 1 says a mechanism is chosen by its differential against the
%% MEASURED drift floor, before it is built. Nothing had measured the floor.
%%
%% The predecessor measured its own at world 22 and found `Ne' 7.44 against a
%% census of 87.95, a floor of 6.72%, and that nearly every mechanism it had ever
%% priced was beneath it. Two of its three headline numbers were invisible and
%% nobody knew for twenty-two worlds. **This runs before the needs, the beliefs
%% and the network, so that if the answer is the same the charter is what changes
%% and not another twenty worlds of results.**
%%
%% ==========================================================================
%% TWO ARMS, AND THE SECOND IS THE ONE THAT COULD HURT
%% ==========================================================================
%%
%% **Uniform.** Everybody equally likely to be copied. `Ne' should land near the
%% census, and if it does not, the model is wrong and every number below is a
%% number about a bug. This arm is the instrument checking itself.
%%
%% **Prestige.** Learners prefer teachers who appear to be doing well. A few
%% teachers then take most of the transmissions, the variance in cultural fitness
%% runs away from its mean, and `Ne' falls.
%%
%% ⚠ **PRESTIGE BIAS IS A MECHANISM THE CHARTER WANTS.** So this asks whether the
%% design contains something that destroys its own measurability, and how much of
%% it is affordable. That question cannot be asked after the fact.
%%
%% ⚠⚠ **STANDING IS INDEPENDENT OF WHAT ANYBODY BELIEVES.** If who gets copied
%% depended on WHAT they held, this would be measuring selection and calling it a
%% floor.
%%
%% ==========================================================================
%% WHAT WOULD COUNT AS AN ANSWER
%% ==========================================================================
%%
%% The floor is `1 / (2·Ne)'. Against the predecessor's own priced mechanisms:
%%
%%     a mechanism worth 1%     needs `Ne' above 50
%%     a mechanism worth 0.25%  needs `Ne' above 200
%%
%% So `Ne' in the hundreds means the charter's ambitions are reachable. `Ne' near
%% ten means they are not, and the charter is wrong rather than the code.
-mode(compile).

main(Args) ->
    Seeds = arg(Args, 1, 8),
    Ticks = arg(Args, 2, 6000),
    io:format("~n~s~n", [line()]),
    io:format("Ne, measured. ~p seeds, ~p ticks each.~n", [Seeds, Ticks]),
    io:format("~s~n~n", [line()]),

    Base = neutral_copying:defaults(),
    io:format("base: ~p~n~n", [maps:remove(seed, Base)]),

    header(),
    Arms = [{"uniform", #{prestige_pct => 0}},
            {"prestige 25", #{prestige_pct => 25}},
            {"prestige 100", #{prestige_pct => 100}},
            {"prestige 400", #{prestige_pct => 400}},
            {"prestige 400, attn 2", #{prestige_pct => 400, attention => 2}},
            {"prestige 400, attn 20", #{prestige_pct => 400, attention => 20}},
            {"prestige 400, attn 99", #{prestige_pct => 400, attention => 99}},
            {"uniform, n=400", #{prestige_pct => 0, n => 400}},
            {"prestige 400, n=400", #{prestige_pct => 400, n => 400}},
            {"prestige 400, n=400, attn 99", #{prestige_pct => 400, n => 400, attention => 99}}],
    lists:foreach(fun({Name, Over}) -> arm(Name, Over, Seeds, Ticks) end, Arms),
    io:format("~n~s~n", [line()]),
    io:format("floor = 1/(2*Ne). 1% needs Ne>50. 0.25% needs Ne>200.~n"),
    io:format("~s~n~n", [line()]).

line() -> lists:duplicate(78, $=).

header() ->
    io:format("~-24s ~7s ~9s ~9s ~9s ~9s ~9s~n",
              ["arm", "census", "Ne decay", "Ne var", "floor %", "k mean",
               "var/mean"]),
    io:format("~s~n", [lists:duplicate(80, $-)]).

arm(Name, Over, Seeds, Ticks) ->
    Runs = [one(maps:merge(Over, #{seed => S}), Ticks) || S <- lists:seq(1, Seeds)],
    Decays = [Ne || #{decay := {ok, Ne}} <- Runs],
    Vars = [Ne || #{variance_ne := Ne} <- Runs],
    Ratios = [R || #{ratio_milli := R} <- Runs],
    Means = [M || #{mean_milli := M} <- Runs],
    N = maps:get(n, maps:merge(neutral_copying:defaults(), Over)),
    report(Name, N, Decays, Vars, Means, Ratios).

report(Name, N, [], _Vars, _Means, _Ratios) ->
    io:format("~-24s ~7w ~9s ~9s ~9s ~9s ~9s~n",
              [Name, N, "no decay", "-", "-", "-", "-"]);
report(Name, N, Decays, Vars, Means, Ratios) ->
    Ne = mean(Decays),
    io:format("~-24s ~7w ~9.1f ~9.1f ~9.3f ~9.2f ~9.2f~n",
              [Name, N, Ne, mean(Vars), effective_size:floor_ppm(Ne) / 10000,
               mean(Means) / 1000, mean(Ratios) / 1000]).

%% ⚠ SAMPLED IN GENERATIONS, NOT IN TICKS. One generation is `n' label
%% replacements, births and adoptions counted together, so the answer does not
%% move when the copying rate does. Ticks would make this measure the copying rate
%% and report it as a population.
one(Over, Ticks) ->
    W0 = neutral_copying:new(Over),
    N = neutral_copying:census(W0),
    Every = max(1, Ticks div 60),
    {Samples, W} = walk(W0, Ticks, Every, N, []),
    #{ratio_milli := Ratio, mean_milli := Mean, ne := VarianceNe} =
        effective_size:from_variance(neutral_copying:completed_teaching(W), N),
    #{decay => effective_size:from_decay(lists:reverse(Samples), N),
      variance_ne => VarianceNe,
      ratio_milli => Ratio,
      mean_milli => Mean}.

walk(W, Left, _Every, _N, Acc) when Left =< 0 ->
    {Acc, W};
walk(W, Left, Every, N, Acc) ->
    Step = min(Every, Left),
    Generations = generations(W, N),
    Diversity = effective_size:diversity_ppm(neutral_copying:labels(W)),
    walk(neutral_copying:run(W, Step), Left - Step, Every, N,
         [{Generations, Diversity} | Acc]).

%% Births are one replacement each and there are `n / lifespan' of them a tick;
%% adoptions are counted directly. Both move a label, so both count.
generations(W, N) ->
    Births = neutral_copying:tick_of(W) * N / lifespan_of(W),
    (neutral_copying:transmissions(W) + Births) / N.

lifespan_of(W) -> maps:get(lifespan, W).

mean([]) -> 0.0;
mean(Xs) -> lists:sum(Xs) / length(Xs).

arg(Args, N, _Default) when length(Args) >= N -> list_to_integer(lists:nth(N, Args));
arg(_Args, _N, Default) -> Default.
