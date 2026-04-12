// Epicue: Equity, Privacy, and Integrity with Cairo in Untrusted Environments
// Healthcare Case Study — Verifiable Public Service Data Registry
// FATE-compliant: Fairness, Accountability, Transparency, Ethics

// ──────────────────────────────────────────────
// Data Types
// ──────────────────────────────────────────────

/// Generalized record submitted for EQUISYS use cases (Healthcare, Water, Industry, etc.).
/// The `subject_id` is a blinded commitment to the entity being reported.
#[derive(Drop, Serde, starknet::Store)]
pub struct EpicueRecord {
    pub subject_id: felt252,      // blinded subject commitment
    pub domain: felt252,          // e.g. 'healthcare', 'water', 'industry'
    pub category: felt252,        // e.g. 'emergency', 'quality_report', 'batch_audit'
    pub severity: u8,             // 1 (low) – 5 (critical)
    pub timestamp: u64,           // Unix epoch
    pub data_hash: felt252,       // Pedersen hash of off-chain payload
}

/// Kept for backwards compatibility with Phase-2 healthcare logic.
#[derive(Drop, Serde, starknet::Store)]
pub struct HealthRecord {
    pub patient_id: felt252,
    pub service_category: felt252,
    pub severity: u8,
    pub timestamp: u64,
    pub data_hash: felt252,
}

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
    fn get_record_count(self: @TContractState) -> u64;

    // Authority management
    fn add_authority(ref self: TContractState, new_authority: starknet::ContractAddress);
    fn is_authority(self: @TContractState, address: starknet::ContractAddress) -> bool;
}

// ──────────────────────────────────────────────
// Contract
// ──────────────────────────────────────────────

#[starknet::contract]
mod Registry {
    use super::HealthRecord;
    use starknet::get_caller_address;
    use starknet::get_block_timestamp;
    use starknet::ContractAddress;
    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess, StoragePointerWriteAccess};

    // ── Storage ────────────────────────────────

    #[storage]
    struct Storage {
        // Phase-1: generic records (user_id → data_hash)
        records: Map<felt252, felt252>,
        // Phase-2: typed healthcare records (kept for legacy support)
        health_records: Map<felt252, HealthRecord>,
        // Phase-3: generalized EQUISYS records
        epicue_records: Map<felt252, EpicueRecord>,
        // Authority registry (AccountAddress → can_submit)
        authorities: Map<ContractAddress, bool>,
        // Transparency counter
        record_count: u64,
    }

    // ── Events ─────────────────────────────────

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        RecordSubmitted: RecordSubmitted,
        HealthRecordSubmitted: HealthRecordSubmitted,
        EpicueRecordSubmitted: EpicueRecordSubmitted,
    }

    /// Emitted on every generic record submission.
    #[derive(Drop, starknet::Event)]
    struct RecordSubmitted {
        #[key]
        user_id: felt252,
        data_hash: felt252,
    }

    /// Emitted on every healthcare record submission.
    #[derive(Drop, starknet::Event)]
    struct HealthRecordSubmitted {
        #[key]
        patient_id: felt252,
        service_category: felt252,
        severity: u8,
        timestamp: u64,
        data_hash: felt252,
    }

    /// Emitted on every generalized EQUISYS record submission.
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
        self.record_count.write(0);
    }

    // ── Interface Implementation ───────────────

    #[abi(embed_v0)]
    impl RegistryImpl of super::IRegistry<ContractState> {

        // ── Phase-1 generic record ──────────────

        fn submit_record(ref self: ContractState, user_id: felt252, data_hash: felt252) {
            let caller = get_caller_address();
            assert(self.authorities.read(caller), 'Unauthorized submission');
            self.records.write(user_id, data_hash);
            let count = self.record_count.read();
            self.record_count.write(count + 1);
            self.emit(Event::RecordSubmitted(RecordSubmitted { user_id, data_hash }));
        }

        fn get_record(self: @ContractState, user_id: felt252) -> felt252 {
            self.records.read(user_id)
        }

        // ── Phase-2 healthcare record ───────────

        fn submit_health_record(ref self: ContractState, record: HealthRecord) {
            // Accountability: only authorized human-in-the-loop entities may submit
            let caller = get_caller_address();
            assert(self.authorities.read(caller), 'Unauthorized submission');

            // Integrity: reject zero patient_id (must be a real blinded commitment)
            assert(record.patient_id != 0, 'Invalid patient commitment');

            // Reasonableness: severity must be 1..5
            assert(record.severity >= 1_u8 && record.severity <= 5_u8, 'Severity out of range');

            let patient_id = record.patient_id;
            let service_category = record.service_category;
            let severity = record.severity;
            let timestamp = record.timestamp;
            let data_hash = record.data_hash;

            self.health_records.write(patient_id, record);

            let count = self.record_count.read();
            self.record_count.write(count + 1);

            // Transparency: emit event so any observer can track submissions
            self.emit(Event::HealthRecordSubmitted(HealthRecordSubmitted {
                patient_id,
                service_category,
                severity,
                timestamp,
                data_hash,
            }));
        }

        fn get_health_record(self: @ContractState, patient_id: felt252) -> HealthRecord {
            self.health_records.read(patient_id)
        }

        // ── Phase-3 generalized record ──────────

        fn submit_epicue_record(ref self: ContractState, record: EpicueRecord) {
            let caller = get_caller_address();
            assert(self.authorities.read(caller), 'Unauthorized submission');

            assert(record.subject_id != 0, 'Invalid subject commitment');
            assert(record.severity >= 1_u8 && record.severity <= 5_u8, 'Severity out of range');

            let subject_id = record.subject_id;
            let domain = record.domain;
            let category = record.category;
            let severity = record.severity;
            let timestamp = record.timestamp;
            let data_hash = record.data_hash;

            self.epicue_records.write(subject_id, record);

            let count = self.record_count.read();
            self.record_count.write(count + 1);

            self.emit(Event::EpicueRecordSubmitted(EpicueRecordSubmitted {
                subject_id,
                domain,
                category,
                severity,
                timestamp,
                data_hash,
            }));
        }

        fn get_epicue_record(self: @ContractState, subject_id: felt252) -> EpicueRecord {
            self.epicue_records.read(subject_id)
        }

        fn get_record_count(self: @ContractState) -> u64 {
            self.record_count.read()
        }

        // ── Authority management ────────────────

        fn add_authority(ref self: ContractState, new_authority: ContractAddress) {
            let caller = get_caller_address();
            assert(self.authorities.read(caller), 'Caller not authority');
            self.authorities.write(new_authority, true);
        }

        fn is_authority(self: @ContractState, address: ContractAddress) -> bool {
            self.authorities.read(address)
        }
    }
}
