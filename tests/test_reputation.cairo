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
    // 30 days = 2592000 seconds
    let jump = 2592000 + 1000;
    start_cheat_block_timestamp(dispatcher.contract_address, t0 + jump);

    // 3. Check decayed reputation (View call)
    let decayed_rep = dispatcher.get_institution_reputation(auth).reputation_credits;
    
    // Deduction = 5% of 50 = 2.5 -> 2 (integer division)
    // Expected: 50 - 2 = 48
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
    
    // Deduction = 2 periods * 5% = 10% of 50 = 5
    // Expected: 50 - 5 = 45
    assert(decayed_rep == 45, 'Cumulative decay mismatch');
}

#[test]
fn test_reputation_floor_enforcement() {
    let auth: ContractAddress = 0x111.try_into().unwrap();
    let dispatcher = deploy_registry(auth);

    let t0 = 100;
    start_cheat_block_timestamp(dispatcher.contract_address, t0);
    start_cheat_caller_address(dispatcher.contract_address, auth);
    
    // 1. Set floor to 40
    dispatcher.set_reputation_floor(40);
    assert(dispatcher.get_reputation_floor() == 40, 'Floor not set');

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
