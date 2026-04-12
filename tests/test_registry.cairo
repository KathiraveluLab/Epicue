use snforge_std::{
    declare, ContractClassTrait, DeclareResult, DeclareResultTrait,
    start_cheat_caller_address, stop_cheat_caller_address,
};
use epicue_core::registry::{IRegistryDispatcher, IRegistryDispatcherTrait};
use epicue_core::types::{HealthRecord, EpicueRecord, domains};
use starknet::ContractAddress;
use core::result::ResultTrait;

// ── Helpers ────────────────────────────────────────────────────────────────

fn deploy_registry(authority: ContractAddress) -> IRegistryDispatcher {
    let declare_result = ResultTrait::unwrap(declare("Registry"));
    let contract = match declare_result {
        DeclareResult::Success(class) => class,
        DeclareResult::AlreadyDeclared(class) => class,
    };
    let mut calldata = array![authority.into()];
    let (contract_address, _) = ResultTrait::unwrap(contract.deploy(@calldata));
    IRegistryDispatcher { contract_address }
}

fn sample_health_record() -> HealthRecord {
    HealthRecord {
        patient_id: 'patient_abc_blinded',
        service_category: 'emergency',
        severity: 3_u8,
        timestamp: 1712800000_u64,
        data_hash: 'sha256_payload_hash',
    }
}

fn sample_epicue_record() -> EpicueRecord {
    EpicueRecord {
        subject_id: 'water_sensor_001',
        domain: domains::WATER,
        category: 'potability',
        severity: 4_u8,
        timestamp: 1712800000_u64,
        data_hash: 'hash_v3_water',
    }
}

// ── Phase-1: Generic Record Tests ─────────────────────────────────────────

#[test]
fn test_submit_and_get_record() {
    let authority: ContractAddress = 0x123.try_into().unwrap();
    let dispatcher = deploy_registry(authority);

    start_cheat_caller_address(dispatcher.contract_address, authority);
    dispatcher.submit_record('user1', 'hash123');
    stop_cheat_caller_address(dispatcher.contract_address);

    let stored = dispatcher.get_record('user1');
    assert(stored == 'hash123', 'Hash mismatch');
}

#[test]
#[should_panic(expected: ('Unauthorized submission', ))]
fn test_unauthorized_submit() {
    let authority: ContractAddress = 0x123.try_into().unwrap();
    let dispatcher = deploy_registry(authority);

    let attacker: ContractAddress = 0x456.try_into().unwrap();
    start_cheat_caller_address(dispatcher.contract_address, attacker);
    dispatcher.submit_record('user1', 'data');
}

// ── Phase-2: Healthcare Record Tests ──────────────────────────────────────

#[test]
fn test_submit_health_record() {
    let authority: ContractAddress = 0x123.try_into().unwrap();
    let dispatcher = deploy_registry(authority);
    let record = sample_health_record();
    let patient_id = record.patient_id;

    start_cheat_caller_address(dispatcher.contract_address, authority);
    dispatcher.submit_health_record(record);
    stop_cheat_caller_address(dispatcher.contract_address);

    let stored = dispatcher.get_health_record(patient_id);
    assert(stored.patient_id == patient_id, 'Patient ID mismatch');
}

#[test]
fn test_record_count_increments() {
    let authority: ContractAddress = 0x123.try_into().unwrap();
    let dispatcher = deploy_registry(authority);

    assert(dispatcher.get_record_count() == 0_u64, 'Initial count should be 0');

    start_cheat_caller_address(dispatcher.contract_address, authority);
    dispatcher.submit_record('user1', 'hash1');
    dispatcher.submit_health_record(sample_health_record());
    stop_cheat_caller_address(dispatcher.contract_address);

    assert(dispatcher.get_record_count() == 2_u64, 'Count should be 2');
}

// ── Phase-3: EQUISYS Generalized Record Tests ─────────────────────────────

#[test]
fn test_submit_epicue_record() {
    let authority: ContractAddress = 0x123.try_into().unwrap();
    let dispatcher = deploy_registry(authority);
    let record = sample_epicue_record();
    let subject_id = record.subject_id;

    start_cheat_caller_address(dispatcher.contract_address, authority);
    dispatcher.submit_epicue_record(record);
    stop_cheat_caller_address(dispatcher.contract_address);

    let stored = dispatcher.get_epicue_record(subject_id);
    assert(stored.subject_id == subject_id, 'Subject ID mismatch');
    assert(stored.domain == domains::WATER, 'Domain mismatch');
}

#[test]
fn test_on_chain_domain_stats() {
    let authority: ContractAddress = 0x123.try_into().unwrap();
    let dispatcher = deploy_registry(authority);

    start_cheat_caller_address(dispatcher.contract_address, authority);
    // Submit 2 water reports and 1 health report
    dispatcher.submit_epicue_record(sample_epicue_record());
    
    let mut rec2 = sample_epicue_record();
    rec2.subject_id = 'water_002';
    dispatcher.submit_epicue_record(rec2);
    
    dispatcher.submit_health_record(sample_health_record());
    stop_cheat_caller_address(dispatcher.contract_address);

    assert(dispatcher.get_domain_count(domains::WATER) == 2_u64, 'Water count mismatch');
    assert(dispatcher.get_domain_count(domains::HEALTHCARE) == 1_u64, 'Health count mismatch');
    assert(dispatcher.get_domain_count(domains::INDUSTRY) == 0_u64, 'Industry count should be 0');
}

#[test]
#[should_panic(expected: ('Caller not authority', ))]
fn test_security_check_fails_for_non_auth() {
    let authority: ContractAddress = 0x123.try_into().unwrap();
    let dispatcher = deploy_registry(authority);

    let attacker: ContractAddress = 0x999.try_into().unwrap();
    start_cheat_caller_address(dispatcher.contract_address, attacker);
    dispatcher.submit_epicue_record(sample_epicue_record());
}
