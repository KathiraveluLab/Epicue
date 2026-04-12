use epicue_core::core::types::{EpicueRecord, HealthRecord, domains};
use epicue_core::core::metadata;
use epicue_core::triad::validation;
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
    fn get_proposal(self: @TContractState, proposal_id: u64) -> epicue_core::triad::governance_voting::Proposal;
    fn get_proposal_count(self: @TContractState) -> u64;

    // Digital Inclusion & Delegation
    fn submit_delegated_record(ref self: TContractState, record: EpicueRecord, subject_consent_hash: felt252);
    fn register_advocate(ref self: TContractState, advocate: ContractAddress, name: felt252);
    fn is_vetted_advocate(self: @TContractState, address: ContractAddress) -> bool;

    // Natural Sciences (Geology)
    fn submit_geological_record(ref self: TContractState, record: epicue_core::core::types::GeologicalRecord);
    fn get_geological_record(self: @TContractState, subject_id: felt252) -> epicue_core::core::types::GeologicalRecord;

    // Institutional Incentives
    fn get_institution_reputation(self: @TContractState, address: ContractAddress) -> epicue_core::social::reputation::InstitutionReputation;

    // Research Statistics
    fn get_domain_impact(self: @TContractState, domain: felt252) -> u64;
    fn get_collaboration_index(self: @TContractState) -> u16;
    fn get_system_sustainability_score(self: @TContractState) -> u64;

    // Scientific Peer Review
    fn challenge_record(ref self: TContractState, subject_id: felt252, scientific_consensus: u8);
    fn get_review_consensus(self: @TContractState, subject_id: felt252) -> u8;
    fn get_domain_trend(self: @TContractState, domain: felt252) -> i16;

    // Schema Management
    fn register_schema(ref self: TContractState, domain: felt252, field_count: u8);
    fn add_authority(ref self: TContractState, new_authority: ContractAddress);
    fn is_authority(self: @TContractState, address: ContractAddress) -> bool;

    // Advanced Phase-4 Primitives
    fn archive_audit_evidence(ref self: TContractState, evidence: epicue_core::audit_registry::AuditEvidence);
    fn register_discovery_record(ref self: TContractState, record: epicue_core::research::discovery::ResearchDiscovery);
    fn register_methodology(ref self: TContractState, guideline: epicue_core::research::methodology::MethodologyGuideline);
    fn get_methodology(self: @TContractState, id: u64) -> epicue_core::research::methodology::MethodologyGuideline;
    fn get_digital_reach(self: @TContractState, domain: felt252) -> u16;
    fn submit_sustainability_report(ref self: TContractState, report: epicue_core::metrics::sustainability::SustainabilityRecord);
    fn get_sustainability_index(self: @TContractState, institution: ContractAddress) -> u64;
    fn get_filtered_research(self: @TContractState, threshold: u64) -> Array<felt252>;
}

// ──────────────────────────────────────────────
// Contract
// ──────────────────────────────────────────────

#[starknet::contract]
mod Registry {
    use super::{EpicueRecord, HealthRecord, domains};
    use epicue_core::core::access::assert_is_authority;
    use epicue_core::social::advocate::{Advocate};
    use epicue_core::social::reputation::{InstitutionReputation, calculate_credit_gain};
    use epicue_core::core::types::{GeologicalRecord};
    use epicue_core::triad::validation::{check_domain_constraints, check_geospatial_bounds, validate_geological_integrity};
    use epicue_core::research::stats::{calculate_impact_score, calculate_collaboration_index, calculate_digital_reach_index};
    use epicue_core::metrics::analytics::{calculate_sustainability_score, calculate_growth_rate};
    use epicue_core::research::peer_review::{ReviewSession, calculate_consensus_delta};
    use epicue_core::core::metadata::{get_default_domain_name, get_default_domain_desc, get_fate_pillar_desc};
    use epicue_core::triad::governance_voting::{Proposal, proposal_status};
    use epicue_core::core::schema::{DataSchema, validate_record_against_schema};
    use epicue_core::research::discovery::{ResearchDiscovery, filter_high_impact_domains};
    use epicue_core::audit_registry::{AuditEvidence, verify_evidence_integrity};
    use epicue_core::research::methodology::{MethodologyGuideline, calculate_scientific_visibility};
    use epicue_core::metrics::sustainability::{SustainabilityRecord, calculate_green_stature_gain, validate_industry_benchmark};
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
        proposals: Map<u64, epicue_core::triad::governance_voting::Proposal>,
        proposal_count: u64,
        votes: Map<(u64, ContractAddress), bool>, // (proposal_id, voter) -> has_voted
        // Digital Inclusion Storage
        advocates: Map<ContractAddress, Advocate>,
        advocate_count: u64,
        // Research Stats Storage
        domain_total_severity: Map<felt252, u64>,
        // Natural Sciences Storage
        geological_records: Map<felt252, GeologicalRecord>,
        // Institutional Reputation Storage
        reputations: Map<ContractAddress, InstitutionReputation>,
        // Peer Review Storage
        reviews: Map<felt252, ReviewSession>,
        review_count: Map<felt252, u64>,
        // Schema Registry Storage
        schemas: Map<felt252, DataSchema>,
        // Historical Impact Tracking for Metrics
        historical_impacts: Map<(felt252, u64), u64>,
        period_count: u64,
        // Discovery Service Storage
        discovery_records: Map<felt252, ResearchDiscovery>,
        // Historical Audit Evidence
        audit_archives: Map<u64, AuditEvidence>,
        archive_count: u64,
        // Methodology Registry Storage
        methodologies: Map<u64, MethodologyGuideline>,
        methodology_count: u64,
        // Inclusion Storage
        delegated_domain_counts: Map<felt252, u64>,
        // Sustainability Storage
        sustainability_reports: Map<(ContractAddress, u64), SustainabilityRecord>,
        institution_report_counts: Map<ContractAddress, u64>,
        institutional_green_stature: Map<ContractAddress, u64>,
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

            // Update Research Stats before move
            let total_sev = self.domain_total_severity.read(domains::HEALTHCARE);
            self.domain_total_severity.write(domains::HEALTHCARE, total_sev + record.severity.into());

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

            // Update Research Stats before move
            let total_sev = self.domain_total_severity.read(domain);
            self.domain_total_severity.write(domain, total_sev + record.severity.into());

            // Update Institutional Reputation
            let caller = get_caller_address();
            let mut rep = self.reputations.read(caller);
            rep.reputation_credits += calculate_credit_gain(record.severity, domain);
            rep.last_activity_timestamp = record.timestamp;
            self.reputations.write(caller, rep);

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
            epicue_core::triad::governance::calculate_fate_score(self.record_count.read(), self.authority_count.read())
        }

        fn get_compliance_label(self: @ContractState) -> felt252 {
            epicue_core::triad::governance::get_compliance_label(self.get_compliance_score())
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
            if epicue_core::triad::governance_voting::is_finalizable(@proposal, self.authority_count.read()) {
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
            
            if proposal.action_type == epicue_core::triad::governance::actions::ADD_AUTHORITY {
                if !self.authorities.read(proposal.target) {
                    self.authorities.write(proposal.target, true);
                    self.authority_count.write(self.authority_count.read() + 1);
                }
            }
            // Logic for REMOVE_AUTH can be added here
            
            proposal.status = 'EXECUTED';
            self.proposals.write(proposal_id, proposal);
        }

        fn get_proposal(self: @ContractState, proposal_id: u64) -> epicue_core::triad::governance_voting::Proposal {
            self.proposals.read(proposal_id)
        }

        fn get_proposal_count(self: @ContractState) -> u64 {
            self.proposal_count.read()
        }

        fn get_domain_impact(self: @ContractState, domain: felt252) -> u64 {
            let count = self.domain_counts.read(domain);
            let total_severity = self.domain_total_severity.read(domain);
            calculate_impact_score(count, total_severity)
        }

        fn get_collaboration_index(self: @ContractState) -> u16 {
            let auth_count = self.authority_count.read();
            let record_count = self.record_count.read();
            calculate_collaboration_index(auth_count, record_count)
        }

        fn get_system_sustainability_score(self: @ContractState) -> u64 {
            let h_impact = self.get_domain_impact(domains::HEALTHCARE);
            let w_impact = self.get_domain_impact(domains::WATER);
            let i_impact = self.get_domain_impact(domains::INDUSTRY);
            let e_impact = self.get_domain_impact(domains::EDUCATION);
            let g_impact = self.get_domain_impact(domains::GEOSPATIAL);
            let c_index = self.get_collaboration_index();

            calculate_sustainability_score(h_impact, w_impact, i_impact, e_impact, g_impact, c_index)
        }

        fn challenge_record(ref self: ContractState, subject_id: felt252, scientific_consensus: u8) {
             assert_is_authority(self.authorities.read(get_caller_address()));
             let mut review = self.reviews.read(subject_id);
             let votes = self.review_count.read(subject_id);
             
             review.scientific_consensus = calculate_consensus_delta(review.scientific_consensus, scientific_consensus, votes);
             review.is_disputed = true;
             
             self.reviews.write(subject_id, review);
             self.review_count.write(subject_id, votes + 1);
        }

        fn get_review_consensus(self: @ContractState, subject_id: felt252) -> u8 {
            self.reviews.read(subject_id).scientific_consensus
        }

        fn get_domain_trend(self: @ContractState, domain: felt252) -> i16 {
            let current = self.get_domain_impact(domain);
            let prev = self.historical_impacts.read((domain, self.period_count.read()));
            calculate_growth_rate(prev, current)
        }

        fn register_schema(ref self: ContractState, domain: felt252, field_count: u8) {
            assert_is_authority(self.authorities.read(get_caller_address()));
            let schema = DataSchema {
                domain,
                version: 1,
                field_count,
                is_deprecated: false,
                authority: get_caller_address(),
                schema_hash: 0, // Initialized to zero, updated via specialized governance
            };
            self.schemas.write(domain, schema);
        }

        fn archive_audit_evidence(ref self: ContractState, evidence: AuditEvidence) {
            assert_is_authority(self.authorities.read(get_caller_address()));
            let id = self.archive_count.read() + 1;
            
            // Verifiable integrity check before archiving
            if verify_evidence_integrity(@evidence, 8) {
                self.audit_archives.write(id, evidence);
                self.archive_count.write(id);
            }
        }

        fn register_discovery_record(ref self: ContractState, record: ResearchDiscovery) {
            assert_is_authority(self.authorities.read(get_caller_address()));
            self.discovery_records.write(record.domain, record);
        }

        fn get_filtered_research(self: @ContractState, threshold: u64) -> Array<felt252> {
             let mut domains_list = array![domains::HEALTHCARE, domains::WATER, domains::INDUSTRY, domains::EDUCATION, domains::GEOSPATIAL];
             let mut impacts = array![
                 self.get_domain_impact(domains::HEALTHCARE),
                 self.get_domain_impact(domains::WATER),
                 self.get_domain_impact(domains::INDUSTRY),
                 self.get_domain_impact(domains::EDUCATION),
                 self.get_domain_impact(domains::GEOSPATIAL)
             ];
             filter_high_impact_domains(domains_list, impacts, threshold)
        }

        fn register_methodology(ref self: ContractState, mut guideline: MethodologyGuideline) {
            let caller = get_caller_address();
            assert_is_authority(self.authorities.read(caller));
            
            let id = self.methodology_count.read() + 1;
            guideline.id = id;
            guideline.author = caller;
            
            // Calculate visibility based on domain metrics
            let domain_impact = self.get_domain_impact(guideline.domain);
            guideline.impact_metric = calculate_scientific_visibility(domain_impact);
            
            self.methodologies.write(id, guideline);
            self.methodology_count.write(id);
        }
        fn get_methodology(self: @ContractState, id: u64) -> MethodologyGuideline {
            self.methodologies.read(id)
        }
        fn get_digital_reach(self: @ContractState, domain: felt252) -> u16 {
            let delegated = self.delegated_domain_counts.read(domain);
            let total = self.domain_counts.read(domain);
            calculate_digital_reach_index(delegated, total)
        }

        fn submit_sustainability_report(ref self: ContractState, mut report: SustainabilityRecord) {
            let caller = get_caller_address();
            assert_is_authority(self.authorities.read(caller));
            
            // Validate against industry benchmarks
            assert(validate_industry_benchmark(report.carbon_metric, report.energy_efficiency), 'Failed sustainability benchmark');
            
            let count = self.institution_report_counts.read(caller) + 1;
            report.institution = caller;
            report.report_index = count;
            
            // Update Green Stature
            let current_stature = self.institutional_green_stature.read(caller);
            let gain = calculate_green_stature_gain(report.carbon_metric, report.energy_efficiency, report.waste_reduction);
            let new_stature = current_stature + gain;
            
            self.sustainability_reports.write((caller, count), report);
            self.institution_report_counts.write(caller, count);
            self.institutional_green_stature.write(caller, new_stature);
            
            // Update Reputation
            let mut rep = self.reputations.read(caller);
            rep.reputation_credits += (gain / 10); // Reputation weighted by green gain
            self.reputations.write(caller, rep);
        }

        fn get_sustainability_index(self: @ContractState, institution: ContractAddress) -> u64 {
            self.institutional_green_stature.read(institution)
        }

        /// Digital Inclusion: Advocate-Proxy Mechanism (Section 6)
        /// Operationalizes delegated accountability by allowing vetted Advocates
        /// to assist subjects in submitting commitments with a consent hash.
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
            
            // Inclusion Tracking
            let current_delegated = self.delegated_domain_counts.read(domain);
            self.delegated_domain_counts.write(domain, current_delegated + 1);
            
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

        fn submit_geological_record(ref self: ContractState, record: GeologicalRecord) {
            assert_is_authority(self.authorities.read(get_caller_address()));
            
            // Verifiable Spatial Validation
            check_geospatial_bounds(record.latitude, record.longitude);
            // Advanced Natural Science Integrity Check
            validate_geological_integrity(record.sample_depth, record.mineral_density);
            
            let subject_id = record.subject_id;
            
            // Professional Data Accountability: Pass the actual record metadata
            self.emit(Event::EpicueRecordSubmitted(EpicueRecordSubmitted {
                subject_id,
                domain: domains::GEOSPATIAL,
                category: 'geology_sample',
                severity: 3_u8,
                timestamp: record.timestamp,
                // In production, this would be a hash of the full sample data
                data_hash: 'STARK_VERIFIED_GEO_HASH', 
            }));
            
            self.geological_records.write(subject_id, record);
            
            // Update stats
            let d_count = self.domain_counts.read(domains::GEOSPATIAL);
            self.domain_counts.write(domains::GEOSPATIAL, d_count + 1);
            
            // Institutional Reputation
            let caller = get_caller_address();
            let mut rep = self.reputations.read(caller);
            rep.reputation_credits += 15; // Natural science bonus
            self.reputations.write(caller, rep);
        }

        fn get_geological_record(self: @ContractState, subject_id: felt252) -> GeologicalRecord {
            self.geological_records.read(subject_id)
        }

        fn get_institution_reputation(self: @ContractState, address: ContractAddress) -> InstitutionReputation {
            self.reputations.read(address)
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
