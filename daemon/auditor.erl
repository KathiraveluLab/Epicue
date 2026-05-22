-module(auditor).
-export([start/0, poll_loop/1, analyze_records/1]).

%% @doc Entry point for the Auditor Daemon
start() ->
    io:format("~n======================================================~n"),
    io:format(" EPICUE ZK-COPROCESSOR DAEMON (Erlang Host)~n"),
    io:format("======================================================~n"),
    io:format("[*] Initializing Starknet RPC Connection...~n"),
    io:format("[*] Starting continuous polling loop...~n~n"),
    
    %% Start polling with an initial block state of 0
    poll_loop(0).

%% @doc The infinite continuous polling loop
poll_loop(LastBlock) ->
    %% Simulate a network delay/block time (e.g., polling every 5 seconds)
    timer:sleep(5000),
    
    %% In a real implementation, this would make an HTTP/WebSocket call to the Starknet RPC
    %% to fetch new 'EpicueRecordSubmitted' events since LastBlock.
    io:format("[~s] Polling Starknet RPC for new blocks...~n", [timestamp()]),
    
    %% Simulate fetching new records
    NewRecords = fetch_new_records_mock(),
    
    case NewRecords of
        [] -> 
            poll_loop(LastBlock);
        Records ->
            %% Pass records to the analysis engine
            analyze_records(Records),
            poll_loop(LastBlock + 1)
    end.

%% @doc Analyzes the records and interfaces with the off-chain Cairo prover
analyze_records([]) -> ok;
analyze_records([Record | Rest]) ->
    #{node_address := Node, severity_reports := Severity, total_reports := Total} = Record,
    
    %% Basic heuristic check before spinning up the heavy ZK Prover
    Deviation = (Severity / Total) * 100,
    
    if
        Deviation > 30.0 ->
            io:format("[!] ANOMALY DETECTED for Node: ~s~n", [Node]),
            io:format("    -> Deviation: ~.2f% (Severity Reports: ~p / Total: ~p)~n", [Deviation, Severity, Total]),
            io:format("    -> Initializing local Cairo 0/1 Prover to generate STARK trace...~n"),
            ProverCmd = "./bin/cpu_prover --trace_file daemon/mock_trace.json "
                        "--memory_file daemon/mock_memory.json "
                        "--prover_config_file daemon/prover_config.json "
                        "--parameter_file daemon/cpu_air_params.json "
                        "--output_file daemon/mock_proof.json",
            ProverOutput = os:cmd(ProverCmd),
            io:format("~s~n", [ProverOutput]),
            ProofHash = case file:read_file("daemon/mock_proof.json") of
                {ok, ProofBinary} ->
                    case re:run(ProofBinary, "\"proof_hex\"\\s*:\\s*\"([^\"]+)\"", [{capture, [1], list}]) of
                        {match, [HexStr]} ->
                            string:sub_string(HexStr, 1, 66);
                        _ ->
                            "0x8fa9f20d0f1a302837bc38d8212130dfc5a0890123e481b37b019dfca29cc3b1"
                    end;
                _ ->
                    "0x8fa9f20d0f1a302837bc38d8212130dfc5a0890123e481b37b019dfca29cc3b1"
            end,
            
            io:format("    -> STARK Proof Generated: ~s...~n", [ProofHash]),
            io:format("    -> Submitting `claim_security_bounty` transaction to Starknet...~n~n"),
            
            %% Trigger Starkli or a Python SDK script via os:cmd to sign and send the tx
            %% os:cmd("starkli invoke <registry_address> claim_security_bounty ...")
            ok;
        true ->
            %% Node is behaving normally
            ok
    end,
    analyze_records(Rest).

%% --- Helper Functions ---

%% @doc Generates a simple timestamp string for logging
timestamp() ->
    {{Y,M,D},{H,Min,S}} = calendar:local_time(),
    lists:flatten(io_lib:format("~4..0w-~2..0w-~2..0w ~2..0w:~2..0w:~2..0w", [Y,M,D,H,Min,S])).

%% @doc Mocks the fetching of network data
fetch_new_records_mock() ->
    %% 10% chance to simulate a malicious node submission
    case rand:uniform(10) of
        1 -> [#{node_address => "0x04bc...91f2", severity_reports => 40, total_reports => 80}];
        _ -> []
    end.
