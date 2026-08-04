%% @doc Who is let in, and the difference between a refusal and a fault.
-module(border_tests).

-include_lib("eunit/include/eunit.hrl").

%% A mind that is entirely fine. Every case here is about the ISLAND's decision,
%% never about the mind, which is the distinction the module exists to hold.
mind() -> #{lineage => 7, generation => 3}.

open_island() -> #{border => open, minds => 10, max_minds => 50}.

%%==============================================================================
%% The two rules there are
%%==============================================================================

an_open_island_with_room_admits_test() ->
    ?assertEqual(admit, border:consider(mind(), open_island())).

a_closed_island_turns_away_and_says_why_test() ->
    Island = (open_island())#{border => closed},
    ?assertEqual({turn_away, closed}, border:consider(mind(), Island)).

a_full_island_turns_away_and_says_why_test() ->
    Island = (open_island())#{minds => 50},
    ?assertEqual({turn_away, full}, border:consider(mind(), Island)).

%% At the boundary rather than past it: `max_minds' is a maximum, so being AT it
%% is being full. An off-by-one here admits one mind more than the island said it
%% would hold, for ever, silently.
being_exactly_at_the_maximum_is_full_test() ->
    Island = (open_island())#{minds => 50, max_minds => 50},
    ?assertEqual({turn_away, full}, border:consider(mind(), Island)),
    Room = (open_island())#{minds => 49, max_minds => 50},
    ?assertEqual(admit, border:consider(mind(), Room)).

%% ORDER IS PART OF THE ANSWER. An island that is both closed and full is closed,
%% because that is the decision it made rather than the circumstance it is in,
%% and a sender told "full" would reasonably try again later.
closed_outranks_full_test() ->
    Island = (open_island())#{border => closed, minds => 99},
    ?assertEqual({turn_away, closed}, border:consider(mind(), Island)).

%% An island state that says nothing about its border or its size is not refused
%% on a guess. Missing keys mean the rule does not apply, rather than the rule
%% failing closed, because failing closed would make every island silently shut
%% the moment a caller forgot a field.
an_island_that_declares_nothing_admits_test() ->
    ?assertEqual(admit, border:consider(mind(), #{})).

%%==============================================================================
%% The boundary guard
%%==============================================================================

%% ⚠ THE DECLARED VOCABULARY AGAINST THE REASONS THE CODE CAN ACTUALLY EMIT.
%%
%% `reasons_so_far/0' is what a page renders and what an operator reads. Nothing
%% makes it agree with the rules, and the two live twenty lines apart, so a rule
%% added with a new word would ship a refusal that no reader has a name for. That
%% is the same class of fault as a field computed and never put on a wire, which
%% the predecessor hit five times in one day, and CHARTER.md's rule 6 exists
%% because a test of either side alone cannot see it.
%%
%% It compares in BOTH directions. A word declared and unreachable is a promise
%% about a policy that does not exist.
every_reason_the_rules_emit_is_declared_and_no_more_test() ->
    Reachable = lists:usort([Why || Island <- island_states(),
                                    {turn_away, Why}
                                        <- [border:consider(mind(), Island)]]),
    ?assertEqual(lists:usort(border:reasons_so_far()), Reachable).

%% One island state per rule, plus the ones that must NOT refuse. When a rule is
%% added this list must grow with it, and the test above fails until it does.
island_states() ->
    [open_island(),
     #{},
     (open_island())#{border => closed},
     (open_island())#{minds => 50}].
