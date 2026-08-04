%% @doc Supervises this service's own processes.
%%
%% NO CHILDREN YET, AND AN EMPTY LIST RATHER THAN A PLACEHOLDER. The service
%% boots, joins the mesh and answers health. It holds no island. A worker that
%% exists to make the list non-empty is a process whose only job is to look like
%% progress.
%%
%% one_for_one because of the shape that is coming. The island's own page, the
%% narrator and the notebook are independent of the island itself: a page that
%% crashes must never take a people with it, and an island whose narrator cannot
%% reach a model carries on believing things regardless.
-module(hecate_society_sup).

-behaviour(supervisor).

-export([start_link/0, init/1]).

start_link() -> supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    {ok, {#{strategy => one_for_one, intensity => 5, period => 10}, []}}.
