use epicue_core::registry::{IRegistryDispatcher, IRegistryDispatcherTrait};
use epicue_core::triad::governance_voting::{proposal_status};
use epicue_core::triad::governance::actions;
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
