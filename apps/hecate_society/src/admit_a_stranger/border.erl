%% @doc WHO IS LET IN. PURE.
%%
%% Ported from the predecessor, where it was built for an artificial-life world
%% on its last day and is more at home here. CHARTER.md makes the reason plain:
%% cultural group selection needs group boundaries that survive contact, and in
%% every published model those boundaries are an assumption. This is the function
%% where they stop being one.
%%
%% ==========================================================================
%% BEING REFUSED IS NOT THE SAME AS BEING BROKEN
%% ==========================================================================
%%
%% A mind may arrive at the gates perfectly intact and still be turned away. That
%% is a decision this island made, and it says nothing whatever about the mind.
%%
%% The predecessor's first crossing did not have this module and made the error
%% the hard way: because the sender let go irrevocably, a refused arrival had
%% nowhere to be, so refusal BECAME destruction, and the design then described
%% that consequence as though it were a property of refusal. It was a transport
%% decision smuggling in a substantive one.
%%
%% So the two questions are asked separately, and by different code:
%%
%%   the codec         IS THIS A MIND AT ALL? Widths, codes, numbers. Fixed,
%%                     technical, not negotiable, and a failure here is nobody:
%%                     there is nothing to hand back.
%%
%%   `consider/2'      WILL WE HAVE IT? A judgement, about a mind that is fine.
%%                     A refusal here hands the mind back, intact.
%%
%% ⚠ THEY ANSWER IN DIFFERENT SHAPES ON PURPOSE, `{error, Why}' against
%% `{turn_away, Why}', so that no caller can collapse the two by accident.
%%
%% ==========================================================================
%% AND THIS IS THE SEAM WHERE POLITICS GOES
%% ==========================================================================
%%
%% ⚠ THE REASON VOCABULARY IS OPEN ON PURPOSE. What an island refuses today is
%% "we are full" and "we are closed". What it may refuse tomorrow is a mind that
%% believes the wrong thing, one whose island never reciprocates, one carrying
%% nothing worth having, or whatever else emerges from islands that answer to
%% different people.
%%
%% Nothing downstream may enumerate the reasons. A reason is a word this island
%% chose, it travels on the fact that reports the refusal, and a reader shows it
%% rather than interpreting it. The day admission policy is something an island
%% EVOLVES rather than something a person configures, this function is the only
%% thing that has to change.
%%
%% ⚠⚠ AND CHARTER.md'S ETHICAL BOUNDARY BINDS THIS MODULE HARDEST. It is the one
%% place in the system whose output most invites being read as a statement about
%% human borders, and it is not one. Nothing here is evidence about any migration
%% policy. The rules below exist because a formal model of cultural group
%% selection requires a group boundary, and for no other reason. The entity is
%% called a MIND rather than a person or a human for the same reason, decided
%% 2026-08-04: these facts go out on a public realm, and "minds refused" cannot be
%% screenshotted into a claim that "persons refused" invites.
-module(border).

-export([consider/2, reasons_so_far/0]).

-type verdict() :: admit | {turn_away, atom()}.
-export_type([verdict/0]).

%% @doc Whether this island will take this mind.
%%
%% Takes the arriving mind and the island's own state, and answers with a word
%% rather than a boolean, because "no" without a reason is the fact that tells a
%% sender nothing and leaves an operator guessing.
%%
%% ⚠ THE MIND IS THE FIRST ARGUMENT AND EVERY RULE SO FAR IGNORES IT. That is
%% worth noticing rather than tidying away: it means admission is currently a
%% property of the island alone, which is the least interesting kind of border
%% there is. The moment a rule reads the mind, this system has a politics.
-spec consider(map(), map()) -> verdict().
consider(Mind, Island) ->
    weighed([fun closed/2, fun crowded/2], Mind, Island).

weighed([], _M, _I) -> admit;
weighed([Rule | Rest], M, I) -> ruled(Rule(M, I), Rest, M, I).

ruled(admit, Rest, M, I) -> weighed(Rest, M, I);
ruled({turn_away, _Why} = No, _Rest, _M, _I) -> No.

%% ==========================================================================
%% The rules, and there are only two of them yet
%% ==========================================================================

%% AN ISLAND MAY SIMPLY DECLINE, and this is the state the predecessor modelled
%% from its first fact and never once acted on: `accepts_migrants' was on the
%% wire for twenty-four worlds and was always false.
closed(_Mind, #{border := closed}) -> {turn_away, closed};
closed(_Mind, _Island) -> admit.

%% AND A FULL ISLAND CANNOT TAKE ANOTHER, which is less a policy than a fact, but
%% it is still the refusal of an intact mind rather than a judgement about one.
crowded(_Mind, #{minds := Held, max_minds := Max}) when Held >= Max ->
    {turn_away, full};
crowded(_Mind, _Island) ->
    admit.

%% @doc Every reason this island can currently give, for a page that wants to say
%% what happened without inventing words.
%%
%% ⚠ NAMED `reasons_so_far' RATHER THAN `reasons', because a closed list here
%% would be a promise that admission policy is finished, and it is the part of
%% this module most likely to grow. Nothing may branch on this being complete.
-spec reasons_so_far() -> [atom()].
reasons_so_far() -> [closed, full].
