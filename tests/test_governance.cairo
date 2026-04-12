use epicue_core::registry::{IRegistryDispatcher, IRegistryDispatcherTrait};
use epicue_core::governance_voting::{proposal_status};
use epicue_core::governance::actions;
use starknet::ContractAddress;
use snforge_std::{declare, ContractClassTrait, DeclareResult, DeclareResultTrait, start_cheat_caller_address, stop_cheat_caller_address};

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

    // Auth1 adds Auth2 manually first (legacy/bootstrap)
    start_cheat_caller_address(dispatcher.contract_address, auth1);
    dispatcher.add_authority(auth2);
    stop_cheat_caller_address(dispatcher.contract_address);

    // Auth1 proposes new Auth3
    let auth3: ContractAddress = 0x333.try_into().unwrap();
    start_cheat_caller_address(dispatcher.contract_address, auth1);
    let prop_id = dispatcher.propose_action(auth3, actions::ADD_AUTHORITY);
    stop_cheat_caller_address(dispatcher.contract_address);

    // Auth2 votes for Auth3
    start_cheat_caller_address(dispatcher.contract_address, auth2);
    dispatcher.vote_on_proposal(prop_id, true);
    stop_cheat_caller_address(dispatcher.contract_address);

    // Proposal should be approved (2 auths, 2 votes for, threshold = 2)
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
    let dispatcher = deploy_registry(auth1);

    let auth2: ContractAddress = 0x222.try_into().unwrap();
    start_cheat_caller_address(dispatcher.contract_address, auth1);
    let prop_id = dispatcher.propose_action(auth2, actions::ADD_AUTHORITY);
    
    // Auth1 attempts to vote again
    dispatcher.vote_on_proposal(prop_id, true);
    stop_cheat_caller_address(dispatcher.contract_address);
}
