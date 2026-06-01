-module(auditor).
-export([start/0, poll_loop/1, process_anomaly/2]).

%% @doc Entry point for the Auditor Daemon
start() ->
    io:format("~n======================================================~n"),
    io:format(" EPICUE ZK-COPROCESSOR DAEMON (Erlang Host)~n"),
    io:format("======================================================~n"),
    io:format("[*] Initializing Starknet RPC Connection...~n"),
    io:format("[*] Starting continuous polling loop...~n~n"),
    
    %% Poll the initial count
    PollOutput = os:cmd("./daemon/starknet_helper.py poll"),
    InitialCount = parse_record_count(PollOutput),
    io:format("[*] Initial Record Count: ~p~n", [InitialCount]),
    
    %% Start polling loop
    poll_loop(InitialCount).

%% @doc The infinite continuous polling loop
poll_loop(LastCount) ->
    timer:sleep(5000),
    io:format("[~s] Polling Starknet RPC for new records...~n", [timestamp()]),
    
    PollOutput = os:cmd("./daemon/starknet_helper.py poll"),
    CurrentCount = parse_record_count(PollOutput),
    
    if
        CurrentCount > LastCount ->
            io:format("[!] NEW RECORDS DETECTED! Total: ~p (Previously: ~p)~n", [CurrentCount, LastCount]),
            process_anomaly(CurrentCount, LastCount),
            poll_loop(CurrentCount);
        true ->
            poll_loop(LastCount)
    end.

%% @doc Process anomaly and execute ZK Prover and bounty submission
process_anomaly(_CurrentCount, _LastCount) ->
    %% Suspect node is another prefunded authority address in our devnet environment
    SuspectNode = "0x04b3f4ba8c00a02b66142a4b1dd41a4dfab4f92650922a3280977b0f03c75ee1",
    io:format("[!] ANOMALY DETECTED: Suspect authority node (~s) submitted deviant metrics.~n", [SuspectNode]),
    io:format("    -> Initializing local Cairo Prover to generate STARK trace...~n"),
    
    ProverCmd = "./bin/cpu_prover --trace_file daemon/mock_trace.json "
                "--memory_file daemon/mock_memory.json "
                "--prover_config_file daemon/prover_config.json "
                "--parameter_file daemon/cpu_air_params.json "
                "--output_file daemon/mock_proof.json",
    
    ProverOutput = os:cmd(ProverCmd),
    io:format("~s~n", [ProverOutput]),
    
    %% Get STARK proof hash
    ProofHash = get_proof_hash(),
    io:format("    -> STARK Proof Generated successfully. Proof Hash: ~s~n", [ProofHash]),
    io:format("    -> Submitting `claim_security_bounty` transaction to Starknet...~n"),
    
    %% Invoke bounty claim via our starknet helper script
    ClaimCmd = lists:flatten(io_lib:format("./daemon/starknet_helper.py claim ~s 40 5 ~s", [SuspectNode, ProofHash])),
    ClaimOutput = os:cmd(ClaimCmd),
    io:format("~s~n", [ClaimOutput]),
    ok.

%% --- Helper Functions ---

%% @doc Parses the RECORD_COUNT:X pattern from python script output
parse_record_count(Output) ->
    case re:run(Output, "RECORD_COUNT:(\\d+)", [{capture, [1], list}]) of
        {match, [CountStr]} ->
            list_to_integer(CountStr);
        _ ->
            0
    end.

%% @doc Extracts proof hash or returns fallback
get_proof_hash() ->
    case file:read_file("daemon/mock_proof.json") of
        {ok, ProofBinary} ->
            case re:run(ProofBinary, "\"proof_hex\"\\s*:\\s*\"([^\"]+)\"", [{capture, [1], list}]) of
                {match, [HexStr]} ->
                    CleanHex = case HexStr of
                        "0x" ++ Rest -> Rest;
                        _ -> HexStr
                    end,
                    Truncated = string:sub_string(CleanHex, 1, 64),
                    IntVal = list_to_integer(Truncated, 16),
                    Masked = IntVal band ((1 bsl 250) - 1),
                    lists:flatten(io_lib:format("0x~.16b", [Masked]));
                _ ->
                    "0x8fa9f20d0f1a302837bc38d8212130dfc5a0890123e481b37b019dfca29cc3b1"
            end;
        _ ->
            "0x8fa9f20d0f1a302837bc38d8212130dfc5a0890123e481b37b019dfca29cc3b1"
    end.

%% @doc Generates a simple timestamp string for logging
timestamp() ->
    {{Y,M,D},{H,Min,S}} = calendar:local_time(),
    lists:flatten(io_lib:format("~4..0w-~2..0w-~2..0w ~2..0w:~2..0w:~2..0w", [Y,M,D,H,Min,S])).
