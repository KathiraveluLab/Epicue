use epicue_core::registry::{IRegistryDispatcher, IRegistryDispatcherTrait};
use epicue_core::triad::governor::{proposal_status};
use epicue_core::triad::governor::actions;
use starknet::ContractAddress;
use snforge_std::{declare, ContractClassTrait, DeclareResult, start_cheat_caller_address, stop_cheat_caller_address};

fn deploy_registry(initial_authority: ContractAddress) -> IRegistryDispatcher {
    let declare_result = declare("Registry").unwrap();
    let contract = match declare_result {
        DeclareResult::Success(class) => class,
        DeclareResult::AlreadyDeclared(class) => class,
    };
    let mut constructor_calldata = array![initial_authority.into()];
    let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();
    IRegistryDispatcher { contract_address }
}

#[test]
fn test_successful_governance_flow() {
    let auth1: ContractAddress = 0x111.try_into().unwrap();
    let auth2: ContractAddress = 0x222.try_into().unwrap();
    let dispatcher = deploy_registry(auth1);

    // Auth1 adds Auth2 via governance (auto-approves since n=1)
    start_cheat_caller_address(dispatcher.contract_address, auth1);
    let prop1 = dispatcher.propose_action(auth2, actions::ADD_AUTHORITY);
    dispatcher.execute_proposal(prop1);
    stop_cheat_caller_address(dispatcher.contract_address);

    // Auth1 proposes new Auth3
    let auth3: ContractAddress = 0x333.try_into().unwrap();
    start_cheat_caller_address(dispatcher.contract_address, auth1);
    let prop_id = dispatcher.propose_action(auth3, actions::ADD_AUTHORITY);
    stop_cheat_caller_address(dispatcher.contract_address);

    // Auth2 votes for Auth3 (n=2, threshold=2)
    start_cheat_caller_address(dispatcher.contract_address, auth2);
    dispatcher.vote_on_proposal(prop_id, true);
    stop_cheat_caller_address(dispatcher.contract_address);

    // Proposal should be approved
    let proposal = dispatcher.get_proposal(prop_id);
    assert(proposal.status == proposal_status::APPROVED, 'Should be approved');

    // Execute proposal
    dispatcher.execute_proposal(prop_id);

    // Verify Auth3 is now an authority
    assert(dispatcher.is_authority(auth3), 'Auth3 should be authority');
}

#[test]
#[should_panic(expected: ('Already voted', ))]
fn test_prevent_double_voting() {
    let auth1: ContractAddress = 0x111.try_into().unwrap();
    let auth2: ContractAddress = 0x222.try_into().unwrap();
    let dispatcher = deploy_registry(auth1);

    // 1. Add auth2 via governance so n=2
    start_cheat_caller_address(dispatcher.contract_address, auth1);
    let prop1 = dispatcher.propose_action(auth2, actions::ADD_AUTHORITY);
    dispatcher.execute_proposal(prop1);
    
    // 2. Propose auth3
    let auth3: ContractAddress = 0x333.try_into().unwrap();
    let prop2 = dispatcher.propose_action(auth3, actions::ADD_AUTHORITY);
    
    // Auth1 (proposer) attempts to vote again. 
    // Status is 'PENDING' because n=2, votes_for=1, threshold=2.
    dispatcher.vote_on_proposal(prop2, true);
    stop_cheat_caller_address(dispatcher.contract_address);
}

#[test]
fn test_weighted_voting_flow() {
    let auth1: ContractAddress = 0x111.try_into().unwrap();
    let auth2: ContractAddress = 0x222.try_into().unwrap();
    let dispatcher = deploy_registry(auth1);

    // Auth1 adds Auth2 via governance (n=1, auto-approves)
    start_cheat_caller_address(dispatcher.contract_address, auth1);
    let prop1 = dispatcher.propose_action(auth2, actions::ADD_AUTHORITY);
    dispatcher.execute_proposal(prop1);
    stop_cheat_caller_address(dispatcher.contract_address);

    // Auth1 proposes to change its own weight to 200 (n=2, proposer votes with weight 100, threshold is 101, so PENDING)
    start_cheat_caller_address(dispatcher.contract_address, auth1);
    let prop_weight = dispatcher.propose_weight_action(auth1, 200);
    stop_cheat_caller_address(dispatcher.contract_address);

    let proposal = dispatcher.get_proposal(prop_weight);
    assert(proposal.status == proposal_status::PENDING, 'Should be pending');

    // Auth2 votes for the weight change (votes_for becomes 200, which is >= 101, status becomes APPROVED)
    start_cheat_caller_address(dispatcher.contract_address, auth2);
    dispatcher.vote_on_proposal(prop_weight, true);
    stop_cheat_caller_address(dispatcher.contract_address);

    let proposal = dispatcher.get_proposal(prop_weight);
    assert(proposal.status == proposal_status::APPROVED, 'Should be approved');

    // Execute the weight change
    dispatcher.execute_proposal(prop_weight);

    // Verify Auth1 now has weight 200 by proposing a new action. 
    // Auth1 proposes Auth3. Total weight is 200 (Auth1) + 100 (Auth2) = 300.
    // Quorum threshold is 151. Auth1's vote is 200, which is >= 151, so it should auto-approve.
    let auth3: ContractAddress = 0x333.try_into().unwrap();
    start_cheat_caller_address(dispatcher.contract_address, auth1);
    let prop2 = dispatcher.propose_action(auth3, actions::ADD_AUTHORITY);
    stop_cheat_caller_address(dispatcher.contract_address);

    let proposal = dispatcher.get_proposal(prop2);
    assert(proposal.status == proposal_status::APPROVED, 'Should be auto-approved');
}

#[test]
#[should_panic(expected: ('Weight exceeds 33% limit', ))]
fn test_weight_upperbound_centralization() {
    let auth1: ContractAddress = 0x111.try_into().unwrap();
    let auth2: ContractAddress = 0x222.try_into().unwrap();
    let auth3: ContractAddress = 0x333.try_into().unwrap();
    let auth4: ContractAddress = 0x444.try_into().unwrap();
    let dispatcher = deploy_registry(auth1);

    // 1. Add Auth2 (n=1 -> n=2)
    start_cheat_caller_address(dispatcher.contract_address, auth1);
    let p2 = dispatcher.propose_action(auth2, actions::ADD_AUTHORITY);
    dispatcher.execute_proposal(p2);
    stop_cheat_caller_address(dispatcher.contract_address);

    // 2. Add Auth3 (n=2 -> n=3)
    start_cheat_caller_address(dispatcher.contract_address, auth1);
    let p3 = dispatcher.propose_action(auth3, actions::ADD_AUTHORITY);
    stop_cheat_caller_address(dispatcher.contract_address);
    
    start_cheat_caller_address(dispatcher.contract_address, auth2);
    dispatcher.vote_on_proposal(p3, true);
    stop_cheat_caller_address(dispatcher.contract_address);
    dispatcher.execute_proposal(p3);

    // 3. Add Auth4 (n=3 -> n=4)
    start_cheat_caller_address(dispatcher.contract_address, auth1);
    let p4 = dispatcher.propose_action(auth4, actions::ADD_AUTHORITY);
    stop_cheat_caller_address(dispatcher.contract_address);
    
    start_cheat_caller_address(dispatcher.contract_address, auth2);
    dispatcher.vote_on_proposal(p4, true);
    stop_cheat_caller_address(dispatcher.contract_address);
    dispatcher.execute_proposal(p4);

    // 4. Auth1 proposes weight of 200 (which exceeds 33% of 400 total potential weight = 132)
    start_cheat_caller_address(dispatcher.contract_address, auth1);
    dispatcher.propose_weight_action(auth1, 200);
    stop_cheat_caller_address(dispatcher.contract_address);
}


