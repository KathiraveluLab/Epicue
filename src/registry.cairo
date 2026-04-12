use epicue_core::types::{EpicueRecord, HealthRecord, domains};
use epicue_core::metadata;
use epicue_core::validation;
use starknet::ContractAddress;

// ──────────────────────────────────────────────
// Interface
// ──────────────────────────────────────────────

#[starknet::interface]
pub trait IRegistry<TContractState> {
    // Phase-1 generalized entry point (kept for backwards compatibility)
    fn submit_record(ref self: TContractState, user_id: felt252, data_hash: felt252);
    fn get_record(self: @TContractState, user_id: felt252) -> felt252;

    // Phase-2 healthcare-specific entry points
    fn submit_health_record(ref self: TContractState, record: HealthRecord);
    fn get_health_record(self: @TContractState, patient_id: felt252) -> HealthRecord;

    // Phase-3 EQUISYS generalized entry points
    fn submit_epicue_record(ref self: TContractState, record: EpicueRecord);
    fn get_epicue_record(self: @TContractState, subject_id: felt252) -> EpicueRecord;
    
    // Accountability & Transparency views (Phase-4 On-chain Metadata)
    fn get_record_count(self: @TContractState) -> u64;
    fn get_domain_count(self: @TContractState, domain: felt252) -> u64;
    fn get_domain_metadata(self: @TContractState, domain: felt252) -> (felt252, felt252); // (name, description)
    fn get_pillar_metadata(self: @TContractState, pillar: felt252) -> felt252; // (description)
    fn get_compliance_score(self: @TContractState) -> u8;
    fn get_compliance_label(self: @TContractState) -> felt252;

    // Authority management
    fn add_authority(ref self: TContractState, new_authority: ContractAddress);
    fn is_authority(self: @TContractState, address: ContractAddress) -> bool;
}

// ──────────────────────────────────────────────
// Contract
// ──────────────────────────────────────────────

#[starknet::contract]
mod Registry {
    use super::{EpicueRecord, HealthRecord, domains};
    use epicue_core::access::assert_is_authority;
    use epicue_core::metadata::{get_default_domain_name, get_default_domain_desc, get_fate_pillar_desc};
    use epicue_core::validation::check_domain_constraints;
    use starknet::get_caller_address;
    use starknet::ContractAddress;
    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess, StoragePointerWriteAccess};

    // ── Storage ────────────────────────────────

    #[storage]
    struct Storage {
        // Phase-1: generic records (user_id → data_hash)
        records: Map<felt252, felt252>,
        // Phase-2: typed healthcare records (legacy)
        health_records: Map<felt252, HealthRecord>,
        // Phase-3: generalized EQUISYS records
        epicue_records: Map<felt252, EpicueRecord>,
        // Authority registry
        authorities: Map<ContractAddress, bool>,
        authority_count: u64,
        // Transparency counters
        record_count: u64,
        // On-chain aggregations for EQUISYS domains
        domain_counts: Map<felt252, u64>,
    }

    // ── Events ─────────────────────────────────

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        RecordSubmitted: RecordSubmitted,
        HealthRecordSubmitted: HealthRecordSubmitted,
        EpicueRecordSubmitted: EpicueRecordSubmitted,
    }

    #[derive(Drop, starknet::Event)]
    struct RecordSubmitted {
        #[key]
        user_id: felt252,
        data_hash: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct HealthRecordSubmitted {
        #[key]
        patient_id: felt252,
        service_category: felt252,
        severity: u8,
        timestamp: u64,
        data_hash: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct EpicueRecordSubmitted {
        #[key]
        subject_id: felt252,
        domain: felt252,
        category: felt252,
        severity: u8,
        timestamp: u64,
        data_hash: felt252,
    }

    // ── Constructor ────────────────────────────

    #[constructor]
    fn constructor(ref self: ContractState, initial_authority: ContractAddress) {
        self.authorities.write(initial_authority, true);
        self.authority_count.write(1);
        self.record_count.write(0);
    }

    // ── Implementation ──────────────────────────

    #[abi(embed_v0)]
    impl RegistryImpl of super::IRegistry<ContractState> {

        fn submit_record(ref self: ContractState, user_id: felt252, data_hash: felt252) {
            assert_is_authority(self.authorities.read(get_caller_address()));
            
            self.records.write(user_id, data_hash);
            self.record_count.write(self.record_count.read() + 1);
            
            self.emit(Event::RecordSubmitted(RecordSubmitted { user_id, data_hash }));
        }

        fn get_record(self: @ContractState, user_id: felt252) -> felt252 {
            self.records.read(user_id)
        }

        fn submit_health_record(ref self: ContractState, record: HealthRecord) {
            assert_is_authority(self.authorities.read(get_caller_address()));
            assert(record.patient_id != 0, 'Invalid patient commitment');
            
            // Verifiable Policy: Move validation on-chain
            check_domain_constraints(domains::HEALTHCARE, record.service_category, record.severity);

            let patient_id = record.patient_id;
            self.health_records.write(patient_id, record);
            
            // Increment global and domain count
            self.record_count.write(self.record_count.read() + 1);
            let d_count = self.domain_counts.read(domains::HEALTHCARE);
            self.domain_counts.write(domains::HEALTHCARE, d_count + 1);

            self.emit(Event::HealthRecordSubmitted(HealthRecordSubmitted {
                patient_id: record.patient_id,
                service_category: record.service_category,
                severity: record.severity,
                timestamp: record.timestamp,
                data_hash: record.data_hash,
            }));
        }

        fn get_health_record(self: @ContractState, patient_id: felt252) -> HealthRecord {
            self.health_records.read(patient_id)
        }

        fn submit_epicue_record(ref self: ContractState, record: EpicueRecord) {
            assert_is_authority(self.authorities.read(get_caller_address()));
            assert(record.subject_id != 0, 'Invalid subject commitment');
            
            // Phase-4: Use modular validation to increase Cairo complexity
            check_domain_constraints(record.domain, record.category, record.severity);

            let subject_id = record.subject_id;
            let domain = record.domain;
            
            self.epicue_records.write(subject_id, record);
            
            // Increment global and domain count
            self.record_count.write(self.record_count.read() + 1);
            let d_count = self.domain_counts.read(domain);
            self.domain_counts.write(domain, d_count + 1);

            self.emit(Event::EpicueRecordSubmitted(EpicueRecordSubmitted {
                subject_id,
                domain,
                category: record.category,
                severity: record.severity,
                timestamp: record.timestamp,
                data_hash: record.data_hash,
            }));
        }

        fn get_epicue_record(self: @ContractState, subject_id: felt252) -> EpicueRecord {
            self.epicue_records.read(subject_id)
        }

        fn get_record_count(self: @ContractState) -> u64 {
            self.record_count.read()
        }

        fn get_domain_count(self: @ContractState, domain: felt252) -> u64 {
            self.domain_counts.read(domain)
        }

        fn get_domain_metadata(self: @ContractState, domain: felt252) -> (felt252, felt252) {
            (get_default_domain_name(domain), get_default_domain_desc(domain))
        }

        fn get_pillar_metadata(self: @ContractState, pillar: felt252) -> felt252 {
            get_fate_pillar_desc(pillar)
        }

        fn get_compliance_score(self: @ContractState) -> u8 {
            epicue_core::governance::calculate_fate_score(self.record_count.read(), self.authority_count.read())
        }

        fn get_compliance_label(self: @ContractState) -> felt252 {
            epicue_core::governance::get_compliance_label(self.get_compliance_score())
        }

        fn add_authority(ref self: ContractState, new_authority: ContractAddress) {
            assert_is_authority(self.authorities.read(get_caller_address()));
            if !self.authorities.read(new_authority) {
                self.authorities.write(new_authority, true);
                self.authority_count.write(self.authority_count.read() + 1);
            }
        }

        fn is_authority(self: @ContractState, address: ContractAddress) -> bool {
            self.authorities.read(address)
        }
    }
}
