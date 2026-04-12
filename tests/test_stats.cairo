use epicue_core::registry::{IRegistryDispatcher, IRegistryDispatcherTrait};
use epicue_core::core::types::{EpicueRecord, domains};
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
fn test_research_impact_calculation() {
    let authority: ContractAddress = 0x111.try_into().unwrap();
    let dispatcher = deploy_registry(authority);

    // Authority submits records with varying severities
    start_cheat_caller_address(dispatcher.contract_address, authority);
    
    let rec1 = EpicueRecord {
        subject_id: 'sub1', domain: domains::WATER, category: 'test',
        severity: 5_u8, timestamp: 1000, data_hash: 'hash1',
    };
    dispatcher.submit_epicue_record(rec1);

    let rec2 = EpicueRecord {
        subject_id: 'sub2', domain: domains::WATER, category: 'test',
        severity: 3_u8, timestamp: 1001, data_hash: 'hash2',
    };
    dispatcher.submit_epicue_record(rec2);
    
    stop_cheat_caller_address(dispatcher.contract_address);

    // Verify Impact Score
    // (2 records * 8 total severity) / 10 = 1.6 -> 1 (rounding)
    let impact = dispatcher.get_domain_impact(domains::WATER);
    assert(impact == 1, 'Impact score mismatch');
}

#[test]
fn test_collaboration_index() {
    let auth1: ContractAddress = 0x111.try_into().unwrap();
    let auth2: ContractAddress = 0x222.try_into().unwrap();
    let dispatcher = deploy_registry(auth1);

    // Add another authority
    start_cheat_caller_address(dispatcher.contract_address, auth1);
    dispatcher.add_authority(auth2);
    
    // Both authorities submit records
    let rec1 = EpicueRecord {
        subject_id: 'sub1', domain: domains::INDUSTRY, category: 'test',
        severity: 1_u8, timestamp: 1000, data_hash: 'hash1',
    };
    dispatcher.submit_epicue_record(rec1);
    stop_cheat_caller_address(dispatcher.contract_address);

    start_cheat_caller_address(dispatcher.contract_address, auth2);
    let rec2 = EpicueRecord {
        subject_id: 'sub2', domain: domains::INDUSTRY, category: 'test',
        severity: 1_u8, timestamp: 1001, data_hash: 'hash2',
    };
    dispatcher.submit_epicue_record(rec2);
    stop_cheat_caller_address(dispatcher.contract_address);

    // Collaboration Index: (2 auths * 100) / 2 records = 100%
    let index = dispatcher.get_collaboration_index();
    assert(index == 100, 'Collab index mismatch');
}
