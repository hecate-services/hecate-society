%% @doc WHICH ISLAND THIS IS, AND WHAT IT IS CALLED. They are not the same thing.
%%
%% Ported from the predecessor's `world_facts', where the distinction was learned
%% rather than designed.
%%
%% ==========================================================================
%% AN ISLAND'S NAME IS NOT ITS IDENTITY
%% ==========================================================================
%%
%% `island/0' is a LABEL. It comes from an environment variable, falls back to
%% the hostname, and `set_island/1' changes it at runtime from this island's own
%% web form. A person types it and it is meant to be typed.
%%
%% ⚠ SO TWO ISLANDS CAN CARRY THE SAME ONE, and in a world made of nodes run by
%% different people they eventually will. Four things break when they do:
%%
%%   - A SPECTATOR MERGES THEM. Facts filed under the name mean two islands
%%     called `beam01' overwrite each other, and the map shows one island
%%     flickering between two different populations.
%%   - THEY LAND ON ONE SQUARE, because a derived layout hashes what it is
%%     given, so one of them is simply invisible.
%%   - MIGRATION BECOMES AMBIGUOUS. "Send this agent to beam01" can deliver it to
%%     the wrong island, lose it, or deliver it twice.
%%   - AND IT IS NOT ONLY AN ACCIDENT. Anyone may type your island's name into
%%     their own form and begin collecting your migrants.
%%
%% ⚠⚠ AND HERE THE THIRD ONE IS WORSE THAN IT WAS. On the predecessor a
%% duplicated migrant was free energy in a world whose books balanced. Here what
%% crosses is a BELIEF, and a belief delivered twice is not an accounting error:
%% it is one teacher counted as two, which is exactly the quantity conformist
%% transmission is defined over. CHARTER.md's first claim is measured against
%% frequencies, and a frequency computed over duplicated teachers is not a
%% measurement of anything.
%%
%% So identity is `island_id/0', which nobody types, and the name is a nickname.
%% Two islands may both be called `beam01' exactly as two people may both be
%% called Raf.
-module(society_identity).

-export([island/0, island_id/0, set_island/1]).

%% @doc What this island is CALLED. Defaults to the host's name, because a
%% machine already has an identity and inventing a second one nobody configures
%% produces a fleet of islands all called "society".
-spec island() -> binary().
island() -> island_name(os:getenv("HECATE_SOCIETY_ISLAND")).

island_name(false) -> hostname();
island_name("") -> hostname();
island_name(Str) -> list_to_binary(string:trim(Str)).

hostname() ->
    {ok, Host} = inet:gethostname(),
    list_to_binary(Host).

%% @doc WHICH ISLAND THIS IS, as against what it is called.
%%
%% 128 bits of randomness, minted once and kept in the data directory. Unique by
%% construction, so no two islands collide by accident however they are named,
%% and stable across restarts and redeploys because the fleet binds that
%% directory from the host.
%%
%% ⚠ THIS DEFEATS ACCIDENT AND NOT IMPERSONATION, and the difference is worth
%% stating rather than glossing over. Nothing signs this, so a node that wanted
%% to claim another island's identity could copy the file. Doing better needs the
%% mesh keypair, and `hecate_om' loads a stable one only when `identity_key_path'
%% is configured, which this service does not set: the pool's key is EPHEMERAL,
%% so an island keyed on it would become a NEW island at every restart. Binding
%% identity to a persisted keypair is named in CHARTER.md under trust and is
%% owed before the first claim.
%%
%% Read once and remembered, because a fact goes out on a timer and this must not
%% become a file read per publish.
-spec island_id() -> binary().
island_id() -> remembered(persistent_term:get({?MODULE, island_id}, undefined)).

remembered(undefined) ->
    Id = minted_or_read(),
    persistent_term:put({?MODULE, island_id}, Id),
    Id;
remembered(Id) ->
    Id.

minted_or_read() ->
    Path = filename:join(hecate_society_service:data_dir(), "island.id"),
    kept(file:read_file(Path), Path).

%% A file that exists and holds nothing usable is treated as absent rather than
%% trusted. A write torn by a crash would otherwise give this island a blank
%% identity for ever, which is the collision it exists to prevent.
kept({ok, Raw}, Path) -> usable(string:trim(Raw), Path);
kept({error, _Absent}, Path) -> mint(Path).

usable(<<Id:32/binary>>, _Path) -> Id;
usable(_Unusable, Path) -> mint(Path).

mint(Path) ->
    Id = binary:encode_hex(crypto:strong_rand_bytes(16), lowercase),
    ok = filelib:ensure_dir(Path),
    ok = file:write_file(Path, Id),
    Id.

%% @doc Rename this island, until it restarts.
%%
%% IT WRITES THE SAME ENVIRONMENT VARIABLE `island/0' ALREADY READS, rather than
%% introducing a second place a name can live. A name held somewhere else would
%% be a second source of truth that disagrees with the config file the moment
%% either changes, and every fact this island publishes carries the name.
%%
%% SO IT DOES NOT PERSIST, and that is a property of the deployment rather than
%% of this function: the environment wins at the next boot. Whatever offers this
%% to a person must say so, and show the config line that would make it
%% permanent.
-spec set_island(binary()) -> ok.
set_island(Name) ->
    true = os:putenv("HECATE_SOCIETY_ISLAND", binary_to_list(Name)),
    ok.
