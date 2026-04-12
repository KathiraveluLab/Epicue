use snforge_std::{
    declare, ContractClassTrait, DeclareResult, DeclareResultTrait,
    start_cheat_caller_address, stop_cheat_caller_address,
};
use epicue_core::registry::{IRegistryDispatcher, IRegistryDispatcherTrait};
use epicue_core::types::{HealthRecord, EpicueRecord, domains};
use starknet::{ContractAddress, felt252_conversions::IntoFelt252};
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

fn sample_epicue_record(domain: felt252) -> EpicueRecord {
    let category = if domain == domains::WATER { 'potability' } 
                  else if domain == domains::INDUSTRY { 'steel_audit' } 
                  else { 'general' };
                  
    EpicueRecord {
        subject_id: 'subject_commitment_v4',
        domain: domain,
        category: category,
        severity: 4_u8,
        timestamp: 1712800000_u64,
        data_hash: 'hash_v4_gen',
    }
}

// ── Phase-1 & 2: Legacy Coverage ───────────────────────────────────────────

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
#[should_panic(expected: ('Caller not authority', ))]
fn test_unauthorized_submit_generic() {
    let authority: ContractAddress = 0x123.try_into().unwrap();
    let dispatcher = deploy_registry(authority);
    let attacker: ContractAddress = 0x456.try_into().unwrap();
    start_cheat_caller_address(dispatcher.contract_address, attacker);
    dispatcher.submit_record('user1', 'data');
}

#[test]
fn test_health_record_integrity() {
    let authority: ContractAddress = 0x123.try_into().unwrap();
    let dispatcher = deploy_registry(authority);
    let record = sample_health_record();

    start_cheat_caller_address(dispatcher.contract_address, authority);
    dispatcher.submit_health_record(record);
    stop_cheat_caller_address(dispatcher.contract_address);

    let stored = dispatcher.get_health_record(record.patient_id);
    assert(stored.patient_id == record.patient_id, 'Integrity check failed');
}

// ── Phase-3: Multi-Domain EQUISYS Verification ────────────────────────────────

#[test]
fn test_multi_domain_aggregation() {
    let authority: ContractAddress = 0x123.try_into().unwrap();
    let dispatcher = deploy_registry(authority);

    start_cheat_caller_address(dispatcher.contract_address, authority);
    // Water domain
    dispatcher.submit_epicue_record(sample_epicue_record(domains::WATER));
    let mut rec2 = sample_epicue_record(domains::WATER);
    rec2.subject_id = 'water_sensor_002';
    dispatcher.submit_epicue_record(rec2);
    
    // Industry domain
    dispatcher.submit_epicue_record(sample_epicue_record(domains::INDUSTRY));
    stop_cheat_caller_address(dispatcher.contract_address);

    assert(dispatcher.get_domain_count(domains::WATER) == 2_u64, 'Water count fail');
    assert(dispatcher.get_domain_count(domains::INDUSTRY) == 1_u64, 'Industry count fail');
    assert(dispatcher.get_record_count() == 3_u64, 'Global count fail');
}

// ── Phase-4: On-chain Metadata & Governance Verification ─────────────────────

#[test]
fn test_on_chain_metadata_retrieval() {
    let authority: ContractAddress = 0x123.try_into().unwrap();
    let dispatcher = deploy_registry(authority);

    let (name, desc) = dispatcher.get_domain_metadata(domains::WATER);
    assert(name == 'Water Quality', 'Meta name mismatch');
    assert(desc == 'Potability & leak alerts', 'Meta desc mismatch');

    let pillar_desc = dispatcher.get_pillar_metadata('Fairness');
    assert(pillar_desc == 'Equitable L2 access costs', 'Pillar meta mismatch');
}

#[test]
fn test_fate_compliance_scoring_logic() {
    let authority: ContractAddress = 0x123.try_into().unwrap();
    let dispatcher = deploy_registry(authority);
    
    // Initial score (base 50 + auth(1))
    let initial_score = dispatcher.get_compliance_score();
    assert(initial_score == 50_u8, 'Initial score fail');

    // Add authorities and records to increase score
    start_cheat_caller_address(dispatcher.contract_address, authority);
    let auth2: ContractAddress = 0x222.try_into().unwrap();
    dispatcher.add_authority(auth2);
    
    // Submit many records
    let mut i = 0;
    while i < 101 {
        dispatcher.submit_record(i.into(), 'data');
        i += 1;
    };
    stop_cheat_caller_address(dispatcher.contract_address);

    let new_score = dispatcher.get_compliance_score();
    // 50 (base) + 30 (auth count 2-10) + 10 (record count > 100) = 90
    assert(new_score == 90_u8, 'Score growth fail');
    assert(dispatcher.get_compliance_label() == 'Excellent', 'Label fail');
}

#[test]
#[should_panic(expected: ('Severity scale: 1-5', ))]
fn test_validation_out_of_range() {
    let authority: ContractAddress = 0x123.try_into().unwrap();
    let dispatcher = deploy_registry(authority);
    let mut record = sample_epicue_record(domains::WATER);
    record.severity = 6_u8; 

    start_cheat_caller_address(dispatcher.contract_address, authority);
    dispatcher.submit_epicue_record(record);
}

#[test]
#[should_panic(expected: ('Critical must not be routine', ))]
fn test_domain_specific_validation_water() {
    let authority: ContractAddress = 0x123.try_into().unwrap();
    let dispatcher = deploy_registry(authority);
    
    let mut record = sample_epicue_record(domains::WATER);
    record.category = 'routine_check';
    record.severity = 4_u8; // Critical severity but routine check category

    start_cheat_caller_address(dispatcher.contract_address, authority);
    dispatcher.submit_epicue_record(record);
}

#[test]
#[should_panic(expected: ('Carbon report minimum priority', ))]
fn test_domain_specific_validation_industry() {
    let authority: ContractAddress = 0x123.try_into().unwrap();
    let dispatcher = deploy_registry(authority);
    
    let mut record = sample_epicue_record(domains::INDUSTRY);
    record.category = 'carbon_footprint';
    record.severity = 1_u8; // Too low for carbon reporting

    start_cheat_caller_address(dispatcher.contract_address, authority);
    dispatcher.submit_epicue_record(record);
}

#[test]
fn test_governance_authority_tracking() {
    let authority: ContractAddress = 0x123.try_into().unwrap();
    let dispatcher = deploy_registry(authority);
    
    assert(dispatcher.is_authority(authority), 'Initial auth check fail');
    
    let new_auth: ContractAddress = 0x789.try_into().unwrap();
    start_cheat_caller_address(dispatcher.contract_address, authority);
    dispatcher.add_authority(new_auth);
    stop_cheat_caller_address(dispatcher.contract_address);
    
    assert(dispatcher.is_authority(new_auth), 'Authority addition fail');
}

#[test]
fn test_epicue_record_recovery() {
    let authority: ContractAddress = 0x123.try_into().unwrap();
    let dispatcher = deploy_registry(authority);
    let record = sample_epicue_record(domains::WATER);

    start_cheat_caller_address(dispatcher.contract_address, authority);
    dispatcher.submit_epicue_record(record);
    stop_cheat_caller_address(dispatcher.contract_address);

    let stored = dispatcher.get_epicue_record(record.subject_id);
    assert(stored.data_hash == record.data_hash, 'Data recovery mismatch');
    assert(stored.domain == domains::WATER, 'Domain recovery mismatch');
}

#[test]
fn test_accountability_scaling() {
    let authority: ContractAddress = 0x123.try_into().unwrap();
    let dispatcher = deploy_registry(authority);
    
    start_cheat_caller_address(dispatcher.contract_address, authority);
    let mut i = 2;
    while i <= 11 {
        let auth: ContractAddress = i.into();
        dispatcher.add_authority(auth);
        i += 1;
    };
    stop_cheat_caller_address(dispatcher.contract_address);
    
    let score = dispatcher.get_compliance_score();
    assert(score == 65_u8, 'Authority scaling score fail');
}

// ── Phase-4 Expansion: Auditor & Integrity Verification ─────────────────────

#[test]
fn test_auditor_basic_checks() {
    use epicue_core::auditor::{perform_basic_audit, get_audit_summary};
    
    let mut record = sample_epicue_record(domains::WATER);
    
    // Healthy record
    assert(perform_basic_audit(record) == true, 'Healthy audit fail');
    
    // Corrupt record (zero timestamp)
    record.timestamp = 0;
    assert(perform_basic_audit(record) == false, 'Timestamp audit fail');
    
    // Corrupt record (invalid severity)
    let mut rec2 = sample_epicue_record(domains::INDUSTRY);
    rec2.severity = 10_u8;
    assert(perform_basic_audit(rec2) == false, 'Severity audit fail');
    
    assert(get_audit_summary(100, 0) == 'System Healthy', 'Label healthy fail');
    assert(get_audit_summary(100, 3) == 'Minor Anomalies', 'Label minor fail');
}

#[test]
fn test_auditor_weighted_severity() {
    use epicue_core::auditor::calculate_weighted_severity;
    
    // 3 reports with average severity (4+4+1)/3 = 3
    let avg = calculate_weighted_severity(3, 9);
    assert(avg == 3_u8, 'Weighted severity fail');
    
    let zero_avg = calculate_weighted_severity(0, 0);
    assert(zero_avg == 0_u8, 'Zero division fail');
}

#[test]
fn test_governance_authority_retention() {
    let authority: ContractAddress = 0x123.try_into().unwrap();
    let dispatcher = deploy_registry(authority);
    
    start_cheat_caller_address(dispatcher.contract_address, authority);
    let auth2: ContractAddress = 0x222.try_into().unwrap();
    dispatcher.add_authority(auth2);
    
    // Duplicate addition should not increment count
    dispatcher.add_authority(auth2);
    stop_cheat_caller_address(dispatcher.contract_address);
    
    // Initial (1) + auth2 (1) = 2
    let score = dispatcher.get_compliance_score();
    // 50 (base) + 30 (auth count 2) = 80
    assert(score == 80_u8, 'Duplicate auth score fail');
}

#[test]
fn test_verifiable_transparency_labels() {
    use epicue_core::governance::get_compliance_label;
    
    assert(get_compliance_label(95) == 'Excellent', 'Label excellent fail');
    assert(get_compliance_label(75) == 'Good', 'Label good fail');
    assert(get_compliance_label(55) == 'Average', 'Label average fail');
    assert(get_compliance_label(30) == 'Review Required', 'Label review fail');
}

#[test]
fn test_equisys_broad_domain_constants() {
    assert(domains::HEALTHCARE == 'healthcare', 'HC constant mismatch');
    assert(domains::WATER == 'water', 'Water constant mismatch');
    assert(domains::INDUSTRY == 'industry', 'Industry constant mismatch');
}

#[test]
fn test_validation_logic_steel_audit() {
    use epicue_core::validation::check_domain_constraints;
    
    // Valid audit
    check_domain_constraints(domains::INDUSTRY, 'steel_audit', 3_u8);
    
    // Should pass: valid carbon report
    check_domain_constraints(domains::INDUSTRY, 'carbon_footprint', 2_u8);
}

#[test]
fn test_authority_escalation() {
    let authority: ContractAddress = 0x123.try_into().unwrap();
    let dispatcher = deploy_registry(authority);
    let auth2: ContractAddress = 0x222.try_into().unwrap();
    let auth3: ContractAddress = 0x333.try_into().unwrap();
    
    start_cheat_caller_address(dispatcher.contract_address, authority);
    dispatcher.add_authority(auth2);
    stop_cheat_caller_address(dispatcher.contract_address);
    
    // Auth2 can add Auth3 (Accountability Pillar: delegated authority)
    start_cheat_caller_address(dispatcher.contract_address, auth2);
    dispatcher.add_authority(auth3);
    stop_cheat_caller_address(dispatcher.contract_address);
    
    assert(dispatcher.is_authority(auth3), 'Delegated authority fail');
}
