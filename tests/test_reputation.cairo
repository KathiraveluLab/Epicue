use epicue_core::registry::{IRegistryDispatcher, IRegistryDispatcherTrait};
use epicue_core::core::types::{EpicueRecord, domains};
use starknet::ContractAddress;
use snforge_std::{declare, ContractClassTrait, DeclareResult, start_cheat_caller_address, stop_cheat_caller_address, start_cheat_block_timestamp};

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

fn governance_set_floor(dispatcher: IRegistryDispatcher, proposer: ContractAddress, new_floor: u128) {
    start_cheat_caller_address(dispatcher.contract_address, proposer);
    // Encoding the floor (u128) as a felt252 address for the proposal target
    let target_felt: felt252 = new_floor.into();
    let target_addr: ContractAddress = target_felt.try_into().unwrap();
    let prop_id = dispatcher.propose_action(target_addr, 'SET_FLOOR');
    // For n=1, it will be auto-approved
    dispatcher.execute_proposal(prop_id);
    stop_cheat_caller_address(dispatcher.contract_address);
}

#[test]
fn test_reputation_decay_over_time() {
    let auth: ContractAddress = 0x111.try_into().unwrap();
    let dispatcher = deploy_registry(auth);

    // 1. Initial activity at T=100
    let t0 = 100;
    start_cheat_block_timestamp(dispatcher.contract_address, t0);
    start_cheat_caller_address(dispatcher.contract_address, auth);
    
    let record = EpicueRecord {
        subject_id: 0x1,
        domain: domains::HEALTHCARE,
        category: 'test',
        severity: 5, // 50 credits
        timestamp: t0,
        data_hash: 0xabc
    };
    dispatcher.submit_epicue_record(record);
    
    let initial_rep = dispatcher.get_institution_reputation(auth).reputation_credits;
    assert(initial_rep == 50, 'Initial rep mismatch');

    // 2. Jump time by 31 days (DECAY_PERIOD is 30 days)
    let jump = 2592000 + 1000;
    start_cheat_block_timestamp(dispatcher.contract_address, t0 + jump);

    // 3. Check decayed reputation (View call)
    let decayed_rep = dispatcher.get_institution_reputation(auth).reputation_credits;
    
    assert(decayed_rep == 48, 'Decay not applied correctly');
}

#[test]
fn test_reputation_cumulative_decay() {
    let auth: ContractAddress = 0x111.try_into().unwrap();
    let dispatcher = deploy_registry(auth);

    let t0 = 100;
    start_cheat_block_timestamp(dispatcher.contract_address, t0);
    start_cheat_caller_address(dispatcher.contract_address, auth);
    
    let record = EpicueRecord {
        subject_id: 0x1,
        domain: domains::HEALTHCARE,
        category: 'test',
        severity: 5, // 50 credits
        timestamp: t0,
        data_hash: 0xabc
    };
    dispatcher.submit_epicue_record(record);

    // Jump by 61 days (2 periods)
    let jump = (2592000 * 2) + 1000;
    start_cheat_block_timestamp(dispatcher.contract_address, t0 + jump);

    let decayed_rep = dispatcher.get_institution_reputation(auth).reputation_credits;
    
    assert(decayed_rep == 45, 'Cumulative decay mismatch');
}

#[test]
fn test_reputation_floor_enforcement() {
    let auth: ContractAddress = 0x111.try_into().unwrap();
    let dispatcher = deploy_registry(auth);

    let t0 = 100;
    start_cheat_block_timestamp(dispatcher.contract_address, t0);
    
    // 1. Set floor to 40 via governance
    governance_set_floor(dispatcher, auth, 40);
    assert(dispatcher.get_reputation_floor() == 40, 'Floor not set');

    start_cheat_caller_address(dispatcher.contract_address, auth);
    // 2. Gain 50 rep
    let record = EpicueRecord {
        subject_id: 0x1,
        domain: domains::HEALTHCARE,
        category: 'test',
        severity: 5, // 50 credits
        timestamp: t0,
        data_hash: 0xabc
    };
    dispatcher.submit_epicue_record(record);

    // 3. Jump time by 10 years (should decay to 0 normally)
    let ten_years: u64 = 31536000 * 10;
    start_cheat_block_timestamp(dispatcher.contract_address, t0 + ten_years);

    // 4. Verify rep halted at floor (40)
    let decayed_rep = dispatcher.get_institution_reputation(auth).reputation_credits;
    assert(decayed_rep == 40, 'Reputation fell below floor');
}

#[test]
fn test_member_onboarding_and_promotion() {
    let auth: ContractAddress = 0x111.try_into().unwrap();
    let dispatcher = deploy_registry(auth);

    let researcher: ContractAddress = 0x222.try_into().unwrap();

    // 1. Initial state: not a member, role is 0
    assert(!dispatcher.is_member(researcher), 'Should not be member initially');
    assert(dispatcher.get_member_role(researcher) == 0, 'Role should be 0');

    // 2. Register member
    start_cheat_caller_address(dispatcher.contract_address, auth);
    dispatcher.register_member(researcher, 'researcher');
    stop_cheat_caller_address(dispatcher.contract_address);

    // 3. Verify registration
    assert(dispatcher.is_member(researcher), 'Should be member');
    assert(dispatcher.get_member_role(researcher) == 'researcher', 'Role should be researcher');

    // 4. Promote member
    start_cheat_caller_address(dispatcher.contract_address, auth);
    dispatcher.promote_researcher(researcher);
    stop_cheat_caller_address(dispatcher.contract_address);

    // 5. Verify promotion
    assert(dispatcher.get_member_role(researcher) == 'senior_researcher', 'Should be senior_researcher');
}

#[test]
#[should_panic(expected: ('Unauthorized promotion',))]
fn test_member_unauthorized_promotion() {
    let auth: ContractAddress = 0x111.try_into().unwrap();
    let dispatcher = deploy_registry(auth);

    let researcher: ContractAddress = 0x222.try_into().unwrap();
    let unauthorized: ContractAddress = 0x333.try_into().unwrap();

    start_cheat_caller_address(dispatcher.contract_address, auth);
    dispatcher.register_member(researcher, 'researcher');
    stop_cheat_caller_address(dispatcher.contract_address);

    // Try to promote from unauthorized caller
    start_cheat_caller_address(dispatcher.contract_address, unauthorized);
    dispatcher.promote_researcher(researcher);
}

#[test]
fn test_multiplier_growth_and_reset() {
    let auth: ContractAddress = 0x111.try_into().unwrap();
    let dispatcher = deploy_registry(auth);

    let t0 = 100;
    start_cheat_block_timestamp(dispatcher.contract_address, t0);
    start_cheat_caller_address(dispatcher.contract_address, auth);
    
    // 1. Initial record
    let record1 = EpicueRecord {
        subject_id: 0x1,
        domain: domains::HEALTHCARE,
        category: 'test',
        severity: 5,
        timestamp: t0,
        data_hash: 0xabc
    };
    dispatcher.submit_epicue_record(record1);
    
    let rep_initial = dispatcher.get_institution_reputation(auth);
    assert(rep_initial.trust_multiplier == 1, 'Initial multiplier not 1');

    // 2. Active participation: submit record after 15 days (less than DECAY_PERIOD 30 days)
    let t1 = t0 + (2592000 / 2); // 15 days
    start_cheat_block_timestamp(dispatcher.contract_address, t1);
    let record2 = EpicueRecord {
        subject_id: 0x2,
        domain: domains::HEALTHCARE,
        category: 'test',
        severity: 5,
        timestamp: t1,
        data_hash: 0xabc
    };
    dispatcher.submit_epicue_record(record2);

    // 3. Active participation: submit record after another 16 days (consecutive duration > 30 days)
    let t2 = t1 + (2592000 / 2) + 86400; // 16 days
    start_cheat_block_timestamp(dispatcher.contract_address, t2);
    let record3 = EpicueRecord {
        subject_id: 0x3,
        domain: domains::HEALTHCARE,
        category: 'test',
        severity: 5,
        timestamp: t2,
        data_hash: 0xabc
    };
    dispatcher.submit_epicue_record(record3);

    let rep_grown = dispatcher.get_institution_reputation(auth);
    assert(rep_grown.trust_multiplier == 2, 'Multiplier did not grow to 2');

    // 4. Inactivity: wait 91 days (exceeds TRUST_RESET_PERIOD of 90 days)
    let t3 = t2 + 7776000 + 1000;
    start_cheat_block_timestamp(dispatcher.contract_address, t3);
    
    // Read reputation (triggers on-the-fly reset check)
    let rep_reset = dispatcher.get_institution_reputation(auth);
    assert(rep_reset.trust_multiplier == 1, 'Multiplier not reset to 1');
}

#[test]
fn test_rehabilitation_reinstatement() {
    let auth: ContractAddress = 0x111.try_into().unwrap();
    let dispatcher = deploy_registry(auth);

    let target: ContractAddress = 0x222.try_into().unwrap();

    // 1. Add target as authority via governance (n=1, auto-approves)
    start_cheat_caller_address(dispatcher.contract_address, auth);
    let prop_add = dispatcher.propose_action(target, 'ADD_AUTH');
    dispatcher.execute_proposal(prop_add);

    assert(dispatcher.is_authority(target), 'Should be authority');
    let rep_initial = dispatcher.get_institution_reputation(target);
    assert(rep_initial.trust_multiplier == 1, 'Initial multiplier not 1');
    assert(rep_initial.reputation_credits == 0, 'Initial credits not 0');

    // 2. Simulate critical fault / byzantine state (slash Target)
    dispatcher.claim_security_bounty(target, 85, 6, 0x123); // Consent deviation 85, total reviews 6 -> Critical fault (severity=3)
    
    // Check that target is isolated
    assert(!dispatcher.is_authority(target), 'Target should be isolated');
    let rep_slashed = dispatcher.get_institution_reputation(target);
    assert(rep_slashed.reputation_credits == 0, 'Credits not slashed to 0');
    
    // 3. Re-add target as authority (Reinstatement)
    let prop_readd = dispatcher.propose_action(target, 'ADD_AUTH');
    dispatcher.execute_proposal(prop_readd);
    
    // Verify target is reinstated with clean slate
    assert(dispatcher.is_authority(target), 'Target should be reinstated');
    let rep_reinstated = dispatcher.get_institution_reputation(target);
    assert(rep_reinstated.trust_multiplier == 1, 'Reinstated mult not 1');
    assert(rep_reinstated.reputation_credits == 0, 'Reinstated credits not 0');
    // rep_reinstated.status should be NodeStatus::Compliant (which evaluates to Compliant under Serde/Store)
}


