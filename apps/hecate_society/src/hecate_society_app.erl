%% @doc OTP application entry.
%%
%% hecate_om:boot/1 wires the mesh, the realm identity and health, then starts
%% this service.
%%
%% ⚠ THE PREDECESSOR'S VERSION OF THIS COMMENT WENT STALE AND STAYED STALE. It
%% said "STORELESS: no store_id/0 or data_dir/0 callback on the service module,
%% so no reckon-db is started" for weeks after the service module grew both
%% callbacks and opened a store. A comment that describes a decision must name
%% the code that carries it, so that moving the code breaks the comment
%% visibly. This one names `hecate_society_service' and says nothing the module
%% does not.
-module(hecate_society_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_Type, _Args) -> hecate_om:boot(hecate_society_service).

stop(_State) -> ok.
