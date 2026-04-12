use snforge_std::{
    declare, ContractClassTrait, DeclareResult, DeclareResultTrait,
    start_cheat_caller_address, stop_cheat_caller_address,
    spy_events, EventSpyAssertionsTrait,
};
use epicue_core::registry::{IRegistryDispatcher, IRegistryDispatcherTrait, HealthRecord, EpicueRecord};
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
        domain: 'water',
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
    assert(stored.service_category == 'emergency', 'Category mismatch');
    assert(stored.severity == 3_u8, 'Severity mismatch');
    assert(stored.data_hash == 'sha256_payload_hash', 'Hash mismatch');
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

#[test]
#[should_panic(expected: ('Invalid patient commitment', ))]
fn test_zero_patient_id_rejected() {
    let authority: ContractAddress = 0x123.try_into().unwrap();
    let dispatcher = deploy_registry(authority);

    let bad_record = HealthRecord {
        patient_id: 0,
        service_category: 'primary_care',
        severity: 1_u8,
        timestamp: 1712800000_u64,
        data_hash: 'some_hash',
    };

    start_cheat_caller_address(dispatcher.contract_address, authority);
    dispatcher.submit_health_record(bad_record);
}

#[test]
#[should_panic(expected: ('Severity out of range', ))]
fn test_invalid_severity_rejected() {
    let authority: ContractAddress = 0x123.try_into().unwrap();
    let dispatcher = deploy_registry(authority);

    let bad_record = HealthRecord {
        patient_id: 'patient_xyz',
        service_category: 'mental_health',
        severity: 6_u8,  // invalid: max is 5
        timestamp: 1712800000_u64,
        data_hash: 'some_hash',
    };

    start_cheat_caller_address(dispatcher.contract_address, authority);
    dispatcher.submit_health_record(bad_record);
}

#[test]
fn test_add_authority_and_submit() {
    let authority: ContractAddress = 0x123.try_into().unwrap();
    let dispatcher = deploy_registry(authority);
    let new_auth: ContractAddress = 0x789.try_into().unwrap();

    // Initial authority adds a new one
    start_cheat_caller_address(dispatcher.contract_address, authority);
    dispatcher.add_authority(new_auth);
    stop_cheat_caller_address(dispatcher.contract_address);

    assert(dispatcher.is_authority(new_auth), 'New auth not registered');

    // New authority submits a record
    start_cheat_caller_address(dispatcher.contract_address, new_auth);
    dispatcher.submit_record('user2', 'hash_new_auth');
    stop_cheat_caller_address(dispatcher.contract_address);

    assert(dispatcher.get_record('user2') == 'hash_new_auth', 'Record missing');
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
    assert(stored.domain == 'water', 'Domain mismatch');
    assert(stored.category == 'potability', 'Category mismatch');
    assert(stored.severity == 4_u8, 'Severity mismatch');
    assert(stored.data_hash == 'hash_v3_water', 'Hash mismatch');
}

#[test]
#[should_panic(expected: ('Invalid subject commitment', ))]
fn test_zero_subject_id_rejected() {
    let authority: ContractAddress = 0x123.try_into().unwrap();
    let dispatcher = deploy_registry(authority);

    let bad_record = EpicueRecord {
        subject_id: 0,
        domain: 'industry',
        category: 'steel_audit',
        severity: 1_u8,
        timestamp: 1712800000_u64,
        data_hash: 'some_hash',
    };

    start_cheat_caller_address(dispatcher.contract_address, authority);
    dispatcher.submit_epicue_record(bad_record);
}
