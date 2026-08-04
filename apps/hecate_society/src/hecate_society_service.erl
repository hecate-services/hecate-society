%% @doc The hecate_om service contract: what this service is and may do.
%%
%% SIX CALLBACKS, ALL REQUIRED. hecate_om calls every one of them during boot,
%% and a missing export fails at startup with `undef' against the live mesh
%% rather than at compile time. Two sibling services learned that the expensive
%% way, so `hecate_society_service_tests' asserts the six are exported.
%%
%% IT ANNOUNCES NOTHING, ON PURPOSE. An island with no people has no capability
%% to offer and asks the realm for authority over no topic. Advertising
%% `society.receive_migrant' before anything can receive one would put a lie on
%% the mesh, and another service could find it and call it. Both lists grow when
%% the thing they name exists.
-module(hecate_society_service).

-behaviour(hecate_om_service).

-export([info/0, start/1, stop/1, health/0, capabilities/0, identity_spec/0]).
%% ==========================================================================
%% AND TWO OPTIONAL ONES, WHICH TURN THE STORE ON
%% ==========================================================================
%%
%% Exporting `store_id/0' and `data_dir/0' together makes `hecate_om:boot/1'
%% open a reckon-db store before this module's `start/1' fires.
%%
%% ⚠ THE reckon-db APPLICATIONS RUN EITHER WAY. `reckon_db', `reckon_evoq',
%% `reckon_gater', `evoq', `khepri' and `ra' start with `hecate_om' whether these
%% callbacks exist or not. What the two add is a STORE: a data directory, an open
%% handle, and something written.
%%
%% ⚠⚠ AND THE MOMENT THEY EXIST, `config/sys.config.src' MUST CARRY THE `evoq'
%% BLOCK. hecate_om then starts a per-store evoq subscription which reads the
%% global log, and that crashes on `{not_configured, event_store_adapter}'
%% without it. evoq starts as a release-boot application before any service's
%% `start/2' runs, so nothing can inject it later. The predecessor put two of
%% three fleet nodes into a boot-crash loop this exact way.
%%
%% ==========================================================================
%% WHY A LIVE SIMULATION WANTS A DURABLE LOG AT ALL
%% ==========================================================================
%%
%% The island itself stays in a `gen_server''s state and is NOT event-sourced.
%% Nothing here replays an island from events and nothing writes a tick.
%%
%% What the store holds is what an island FOUND. In an open-ended search the
%% interesting thing is by definition the thing nobody anticipated, and an
%% instrument you did not write cannot measure it. A durable record can be
%% re-read next month with a question that did not exist today.
%%
%% ⚠ AND HERE THAT RECORD IS LOAD-BEARING RATHER THAN A CONVENIENCE. CHARTER.md
%% makes the first instrument "did a belief outlive every person that held it",
%% which is a question about a span of time longer than any process that was
%% alive for it. There is no version of that measurement without a durable log.
-export([store_id/0, data_dir/0]).

info() ->
    #{name => <<"hecate-society">>,
      version => <<"0.1.0">>,
      description => <<"One island: a people who hold beliefs, teach them, "
                       "and decide who may land">>}.

start(_Opts) -> hecate_society_sup:start_link().

stop(_State) -> ok.

%% Green once the service is up. A dark mesh is deliberately NOT a health
%% failure: an island whose neighbours are unreachable is still an island, and
%% CHARTER.md makes that the point rather than an inconvenience. A partition is a
%% geographic barrier, its people carry on believing what they believe, and the
%% only thing lost is that nobody else hears about it.
health() -> ok.

%% WHAT THIS SERVICE ANNOUNCES IT CAN DO. Nothing yet, and that is not an
%% oversight. A capability is a promise that something answers when another
%% service calls it. Accepting a migrant is the first real one and it goes here
%% together with the code that accepts one.
capabilities() -> [].

%% THE AUTHORITY THIS SERVICE ASKS THE REALM FOR.
%%
%% ⚠ AN EMPTY RESOURCE LIST, MATCHING AN ISLAND THAT PUBLISHES NOTHING. A scope
%% asked for before it is used is a credential lying around with no owner, and
%% popping it would grant an attacker the ability to post on this island's behalf
%% about a thing that does not exist yet. The topics arrive here in the same
%% commit as the code that publishes them.
identity_spec() ->
    #{scope => <<"society">>,
      actions => [<<"publish">>],
      resources => [],
      ttl_days => 30}.

%% ==========================================================================
%% The store
%% ==========================================================================

%% @doc The reckon-db store this island owns.
%%
%% One per island rather than one per run: a run is a STREAM inside it, so a node
%% that has hosted forty populations can be asked what all forty found, which is
%% the question the whole thing exists to answer.
-spec store_id() -> atom().
store_id() -> society_store.

%% @doc Where it lives on disk.
%%
%% ⚠ DEFAULTS TO A PATH INSIDE THE CONTAINER AND MUST NOT STAY THERE ON A NODE.
%% The beam fleet boots from a 29GB eMMC with a 13GB root and keeps application
%% data on its `/bulk' drives, so the compose file mounts one and sets this. The
%% default is what a laptop wants; a container without the mount loses its record
%% on every recreate, which is the same as not keeping one.
%%
%% ⚠⚠ AND THE ISLAND'S IDENTITY LIVES IN THIS DIRECTORY TOO. `society_identity'
%% mints 128 bits here once and reads them for ever after, so a deployment that
%% forgets the mount does not merely lose the notebook: the island becomes a NEW
%% island at every restart, and every fact it ever published is orphaned.
-spec data_dir() -> string().
data_dir() -> chosen(os:getenv("HECATE_SOCIETY_DATA_DIR")).

chosen(false) -> "/tmp/hecate_society";
chosen("") -> "/tmp/hecate_society";
chosen(Path) -> Path.
