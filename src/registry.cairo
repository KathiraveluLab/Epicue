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

    // Governance Voting
    fn propose_action(ref self: TContractState, target: ContractAddress, action_type: felt252) -> u64;
    fn vote_on_proposal(ref self: TContractState, proposal_id: u64, support: bool);
    fn execute_proposal(ref self: TContractState, proposal_id: u64);
    fn get_proposal(self: @TContractState, proposal_id: u64) -> epicue_core::governance_voting::Proposal;
    fn get_proposal_count(self: @TContractState) -> u64;

    // Digital Inclusion & Delegation
    fn submit_delegated_record(ref self: TContractState, record: EpicueRecord, subject_consent_hash: felt252);
    fn register_advocate(ref self: TContractState, advocate: ContractAddress, name: felt252);
    fn is_vetted_advocate(self: @TContractState, address: ContractAddress) -> bool;

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
    use epicue_core::governance_voting::{Proposal, proposal_status, is_finalizable, get_quorum_threshold};
    use epicue_core::advocate::{Advocate};
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
        // Governance Voting Storage
        proposals: Map<u64, Proposal>,
        proposal_count: u64,
        votes: Map<(u64, ContractAddress), bool>, // (proposal_id, voter) -> has_voted
        // Digital Inclusion Storage
        advocates: Map<ContractAddress, Advocate>,
        advocate_count: u64,
    }

    // ── Events ─────────────────────────────────

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        RecordSubmitted: RecordSubmitted,
        HealthRecordSubmitted: HealthRecordSubmitted,
        EpicueRecordSubmitted: EpicueRecordSubmitted,
        DelegatedSubmission: DelegatedSubmission,
    }

    #[derive(Drop, starknet::Event)]
    struct RecordSubmitted {
        #[key]
        user_id: felt252,
        data_hash: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct DelegatedSubmission {
        #[key]
        subject_id: felt252,
        #[key]
        advocate: ContractAddress,
        domain: felt252,
        timestamp: u64,
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
        self.proposal_count.write(0);
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

            // Emit event before move
            self.emit(Event::HealthRecordSubmitted(HealthRecordSubmitted {
                patient_id: record.patient_id,
                service_category: record.service_category,
                severity: record.severity,
                timestamp: record.timestamp,
                data_hash: record.data_hash,
            }));

            let patient_id = record.patient_id;
            self.health_records.write(patient_id, record);
            
            // Increment global and domain count
            self.record_count.write(self.record_count.read() + 1);
            let d_count = self.domain_counts.read(domains::HEALTHCARE);
            self.domain_counts.write(domains::HEALTHCARE, d_count + 1);
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
            
            // Emit event before move
            self.emit(Event::EpicueRecordSubmitted(EpicueRecordSubmitted {
                subject_id,
                domain,
                category: record.category,
                severity: record.severity,
                timestamp: record.timestamp,
                data_hash: record.data_hash,
            }));

            self.epicue_records.write(subject_id, record);
            
            // Increment global and domain count
            self.record_count.write(self.record_count.read() + 1);
            let d_count = self.domain_counts.read(domain);
            self.domain_counts.write(domain, d_count + 1);
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

        fn propose_action(ref self: ContractState, target: ContractAddress, action_type: felt252) -> u64 {
            let caller = get_caller_address();
            assert_is_authority(self.authorities.read(caller));
            
            let id = self.proposal_count.read() + 1;
            let proposal = Proposal {
                id,
                proposer: caller,
                target,
                action_type,
                votes_for: 1, // Proposer automatically votes for
                votes_against: 0,
                status: proposal_status::PENDING,
                end_block: 0, // Simplified for now
            };
            
            self.proposals.write(id, proposal);
            self.proposal_count.write(id);
            self.votes.write((id, caller), true);
            
            id
        }

        fn vote_on_proposal(ref self: ContractState, proposal_id: u64, support: bool) {
            let caller = get_caller_address();
            assert_is_authority(self.authorities.read(caller));
            
            let mut proposal = self.proposals.read(proposal_id);
            assert(proposal.status == proposal_status::PENDING, 'Proposal not active');
            assert(!self.votes.read((proposal_id, caller)), 'Already voted');
            
            if support {
                proposal.votes_for += 1;
            } else {
                proposal.votes_against += 1;
            }
            
            self.votes.write((proposal_id, caller), true);
            
            // Check if threshold reached
            if is_finalizable(@proposal, self.authority_count.read()) {
                if proposal.votes_for > proposal.votes_against {
                    proposal.status = proposal_status::APPROVED;
                } else {
                    proposal.status = proposal_status::REJECTED;
                }
            }
            
            self.proposals.write(proposal_id, proposal);
        }

        fn execute_proposal(ref self: ContractState, proposal_id: u64) {
            let mut proposal = self.proposals.read(proposal_id);
            assert(proposal.status == proposal_status::APPROVED, 'Not approved');
            
            if proposal.action_type == epicue_core::governance::actions::ADD_AUTHORITY {
                if !self.authorities.read(proposal.target) {
                    self.authorities.write(proposal.target, true);
                    self.authority_count.write(self.authority_count.read() + 1);
                }
            }
            // Logic for REMOVE_AUTH can be added here
            
            proposal.status = 'EXECUTED';
            self.proposals.write(proposal_id, proposal);
        }

        fn get_proposal(self: @ContractState, proposal_id: u64) -> Proposal {
            self.proposals.read(proposal_id)
        }

        fn get_proposal_count(self: @ContractState) -> u64 {
            self.proposal_count.read()
        }

        fn submit_delegated_record(ref self: ContractState, record: EpicueRecord, subject_consent_hash: felt252) {
            let caller = get_caller_address();
            let mut advocate = self.advocates.read(caller);
            assert(advocate.is_active, 'Caller not vetted advocate');
            assert(subject_consent_hash != 0, 'Missing subject consent');

            // Domain validation
            check_domain_constraints(record.domain, record.category, record.severity);

            let subject_id = record.subject_id;
            let domain = record.domain;

            // Emit delegation event
            self.emit(Event::DelegatedSubmission(DelegatedSubmission {
                subject_id,
                advocate: caller,
                domain,
                timestamp: record.timestamp,
            }));

            // Emit standard record event
            self.emit(Event::EpicueRecordSubmitted(EpicueRecordSubmitted {
                subject_id,
                domain,
                category: record.category,
                severity: record.severity,
                timestamp: record.timestamp,
                data_hash: record.data_hash,
            }));

            // Store record
            self.epicue_records.write(subject_id, record);
            
            // Update counts
            self.record_count.write(self.record_count.read() + 1);
            let d_count = self.domain_counts.read(domain);
            self.domain_counts.write(domain, d_count + 1);
            
            // Update advocate metrics
            advocate.records_assisted += 1;
            self.advocates.write(caller, advocate);
        }

        fn register_advocate(ref self: ContractState, advocate: ContractAddress, name: felt252) {
            // Only authorities can register advocates (controlled via Governor)
            assert_is_authority(self.authorities.read(get_caller_address()));
            
            let adv_struct = Advocate {
                address: advocate,
                name,
                is_active: true,
                records_assisted: 0,
            };
            
            self.advocates.write(advocate, adv_struct);
            self.advocate_count.write(self.advocate_count.read() + 1);
        }

        fn is_vetted_advocate(self: @ContractState, address: ContractAddress) -> bool {
            self.advocates.read(address).is_active
        }

        fn add_authority(ref self: ContractState, new_authority: ContractAddress) {
            // Deprecated in favor of voting, but kept for legacy auths or simplified testing
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
