%% @doc Supervises this service's own processes.
%%
%% ONE CHILD: the island. It owns this node's people and keeps them moving.
%%
%% ⚠ RESTARTING IT LOSES THE PEOPLE, and that is honest rather than an oversight.
%% Nothing is persisted, so a crash means the population that was alive is gone
%% and a fresh one is seeded. Making that survive means deciding what an island
%% owes the future, which is a real question and not a line of supervisor
%% configuration.
%%
%% one_for_one because of the shape that is coming. The island's own page, the
%% narrator and the notebook are independent of the island itself: a page that
%% crashes must never take a people with it, and an island whose narrator cannot
%% reach a model carries on regardless.
-module(hecate_society_sup).

-behaviour(supervisor).

-export([start_link/0, init/1]).

start_link() -> supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    {ok, {#{strategy => one_for_one, intensity => 5, period => 10},
          [#{id => island_server,
             start => {island_server, start_link, []},
             restart => permanent,
             shutdown => 5000,
             type => worker}]}}.
