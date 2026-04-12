use epicue_core::research::peer_review::{calculate_bft_consensus, verify_bft_quorum};
use epicue_core::triad::auditor::{detect_byzantine_fault};
use epicue_core::registry::{IRegistryDispatcher, IRegistryDispatcherTrait};
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

fn governance_add_authority(dispatcher: IRegistryDispatcher, proposer: ContractAddress, new_auth: ContractAddress) {
    start_cheat_caller_address(dispatcher.contract_address, proposer);
    let prop_id = dispatcher.propose_action(new_auth, 'ADD_AUTH');
    
    // Proposer automatically votes 'for' in propose_action.
    // If there's only 1 authority, we need to transition status to APPROVED.
    // In registry.cairo, propose_action doesn't transition status.
    // We'll call vote_on_proposal with a DIFFERENT authority or fix the logic.
    // For now, let's just make dispatcher.execute_proposal directly if approved.
    
    // Optimization: In our test, if n=1, threshold=1. proposer is 1 vote.
    // But we need to call something that sets status = APPROVED.
    // I'll add a second authority first if needed, or just update propose_action.
    
    // Actually, I'll just manually finalize it for the test if status is still PENDING.
    // Wait, the dispatcher can't manually set status.
    
    // I'll fix Registry.propose_action to check for finalization.
    dispatcher.execute_proposal(prop_id);
    stop_cheat_caller_address(dispatcher.contract_address);
}

#[test]
fn test_median_consensus_resilience() {
    let h1: u8 = 90;
    let h2: u8 = 88;
    let h3: u8 = 92;
    let b1: u8 = 0; 

    let consensus = calculate_bft_consensus(h1, h2, h3, b1);
    
    assert(consensus > 65, 'Consensus skewed by byzantine');
    assert(consensus < 95, 'Consensus unrealistic');
}

#[test]
fn test_quorum_enforcement() {
    assert(verify_bft_quorum(3, 4) == true, '3 of 4 should be quorum');
    assert(verify_bft_quorum(2, 4) == false, '2 of 4 should fail quorum');
    assert(verify_bft_quorum(4, 4) == true, '4 of 4 should be quorum');
}

#[test]
fn test_byzantine_fault_flagging() {
    let is_byzantine = detect_byzantine_fault(40, 5);
    assert(is_byzantine == true, 'Deviant node should be flagged');
    
    let is_honest = detect_byzantine_fault(10, 5);
    assert(is_honest == false, 'Honest node incorrectly flagged');
}

#[test]
fn test_bounty_collection_simulation() {
    let auditor: ContractAddress = 0x111.try_into().unwrap();
    let byzantine_node: ContractAddress = 0x666.try_into().unwrap();
    let dispatcher = deploy_registry(auditor);

    let initial_bounty = dispatcher.get_bounty_balance(auditor);
    assert(initial_bounty == 0, 'Initial bounty should be 0');

    // Add node as authority via governance
    governance_add_authority(dispatcher, auditor, byzantine_node);

    start_cheat_caller_address(dispatcher.contract_address, auditor);
    dispatcher.claim_security_bounty(byzantine_node);
    stop_cheat_caller_address(dispatcher.contract_address);

    let final_bounty = dispatcher.get_bounty_balance(auditor);
    assert(final_bounty > 0, 'Bounty not awarded');
}

#[test]
#[should_panic(expected: ('BFT Quorum not reached', ))]
fn test_methodology_registration_bft_failure() {
    let auth1: ContractAddress = 0x111.try_into().unwrap();
    let auth2: ContractAddress = 0x222.try_into().unwrap();
    let dispatcher = deploy_registry(auth1);

    // Add auth2 via governance
    governance_add_authority(dispatcher, auth1, auth2);

    use epicue_core::research::methodology::{MethodologyGuideline};
    let guideline = MethodologyGuideline {
        id: 1, // Methodology ID 1
        title: 'Byzantine Test',
        author: auth1,
        domain: 'healthcare',
        content_hash: 'ipfs://test',
        version: 1,
        timestamp: 123456,
        impact_metric: 10
    };
    
    // Attempt registration with ONLY 1 endorsement (from author)
    // We need 2f+1. With n=2, f=0, so required = 1.
    // Wait, let's add a third authority to make n=3, f=0, required=1.
    // Let's add 4 authorities: n=4, f=1, required=2*1+1 = 3.
    let auth3: ContractAddress = 0x333.try_into().unwrap();
    let auth4: ContractAddress = 0x444.try_into().unwrap();
    governance_add_authority(dispatcher, auth1, auth3);
    governance_add_authority(dispatcher, auth1, auth4);

    // Now n=4. Quorum required = 3.
    // Endorsements: auth2 (1)
    start_cheat_caller_address(dispatcher.contract_address, auth2);
    dispatcher.endorse_methodology(1);
    stop_cheat_caller_address(dispatcher.contract_address);

    // Endorsements: auth3 (2)
    start_cheat_caller_address(dispatcher.contract_address, auth3);
    dispatcher.endorse_methodology(1);
    stop_cheat_caller_address(dispatcher.contract_address);

    // Total = 2. Required = 3. Should panic.
    start_cheat_caller_address(dispatcher.contract_address, auth2);
    dispatcher.register_methodology(guideline);
    stop_cheat_caller_address(dispatcher.contract_address);
}

#[test]
fn test_graded_slashing_minor() {
    let auth1: ContractAddress = 0x111.try_into().unwrap();
    let deviant_node: ContractAddress = 0x444.try_into().unwrap();
    let dispatcher = deploy_registry(auth1);

    governance_add_authority(dispatcher, auth1, deviant_node);

    // 2. Bootstrap deviant_node with reputation
    start_cheat_caller_address(dispatcher.contract_address, deviant_node);
    use epicue_core::core::types::{EpicueRecord, domains};
    let record = EpicueRecord {
        subject_id: 0x123,
        domain: domains::HEALTHCARE,
        category: 'test',
        severity: 5, 
        timestamp: 100,
        data_hash: 0xabc
    };
    dispatcher.submit_epicue_record(record);
    stop_cheat_caller_address(dispatcher.contract_address);

    let initial_rep = dispatcher.get_institution_reputation(deviant_node).reputation_credits;
    assert(initial_rep == 50, 'Should have 50 reputation');
    
    // 3. Claim bounty for MINOR fault
    start_cheat_caller_address(dispatcher.contract_address, auth1);
    dispatcher.claim_security_bounty(deviant_node);
    stop_cheat_caller_address(dispatcher.contract_address);

    let final_rep = dispatcher.get_institution_reputation(deviant_node).reputation_credits;
    assert(final_rep == 37, 'Reputation should be 37');
    assert(dispatcher.is_authority(deviant_node), 'Minor fault: retain auth');
}

#[test]
#[should_panic(expected: ('Direct auth update forbidden', ))]
fn test_prevent_direct_authority_update() {
    let auth1: ContractAddress = 0x111.try_into().unwrap();
    let dispatcher = deploy_registry(auth1);
    
    start_cheat_caller_address(dispatcher.contract_address, auth1);
    dispatcher.add_authority(0x222.try_into().unwrap());
    stop_cheat_caller_address(dispatcher.contract_address);
}
