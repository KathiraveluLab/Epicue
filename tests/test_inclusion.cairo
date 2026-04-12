use epicue_core::registry::{IRegistryDispatcher, IRegistryDispatcherTrait};
use epicue_core::types::{EpicueRecord, domains};
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
fn test_delegated_submission_flow() {
    let authority: ContractAddress = 0x111.try_into().unwrap();
    let advocate: ContractAddress = 0x222.try_into().unwrap();
    let dispatcher = deploy_registry(authority);

    // Authority registers an Advocate
    start_cheat_caller_address(dispatcher.contract_address, authority);
    dispatcher.register_advocate(advocate, 'Social Worker');
    stop_cheat_caller_address(dispatcher.contract_address);

    // Advocate submits for a subject
    let record = EpicueRecord {
        subject_id: 'subject_001',
        domain: domains::HEALTHCARE,
        category: 'consultation',
        severity: 2_u8,
        timestamp: 1712800000_u64,
        data_hash: 'consent_verified_hash',
    };

    let sid = record.subject_id;
    let hash = record.data_hash;

    start_cheat_caller_address(dispatcher.contract_address, advocate);
    dispatcher.submit_delegated_record(record, 'subject_consent_token');
    stop_cheat_caller_address(dispatcher.contract_address);

    // Verify record recovery
    let stored = dispatcher.get_epicue_record(sid);
    assert(stored.data_hash == hash, 'Delegated data mismatch');
}

#[test]
#[should_panic(expected: ('Caller not vetted advocate', ))]
fn test_unauthorized_delegation() {
    let authority: ContractAddress = 0x111.try_into().unwrap();
    let stranger: ContractAddress = 0x444.try_into().unwrap();
    let dispatcher = deploy_registry(authority);

    let record = EpicueRecord {
        subject_id: 'subject_002',
        domain: domains::WATER,
        category: 'leak_report',
        severity: 1_u8,
        timestamp: 1712800000_u64,
        data_hash: 'unauthorized_hash',
    };

    // Stranger attempts to submit for subject
    start_cheat_caller_address(dispatcher.contract_address, stranger);
    dispatcher.submit_delegated_record(record, 'fake_consent');
    stop_cheat_caller_address(dispatcher.contract_address);
}
