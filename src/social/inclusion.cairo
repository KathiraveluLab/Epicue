/// Digital Inclusion Module
/// Operationalizes the "Advocate-Proxy" mechanism for vulnerable groups.

use epicue_core::research::stats::calculate_digital_reach_index;

#[derive(Drop, Serde, starknet::Store)]
pub struct InclusionSummary {
    pub domain: felt252,
    pub reach_index: u16, // Digital Reach Index (DRI)
    pub total_delegated: u64,
    pub total_records: u64,
}

/// Inclusion Gap Analysis (Section 6.1)
/// Detects if a domain is neglecting vulnerable populations.
pub fn check_inclusion_gap(reach_index: u16, total_records: u64) -> bool {
    // If a domain has over 100 records but a DRI < 5%, it has an inclusion gap
    if total_records > 100 && reach_index < 500 {
        return true;
    }
    false
}

pub fn get_inclusion_label(reach_index: u16) -> felt252 {
    if reach_index >= 3000 { 'EXCELLENT_INCLUSION' }
    else if reach_index >= 1500 { 'GOOD_INCLUSION' }
    else if reach_index >= 500 { 'FAIR_INCLUSION' }
    else { 'INCLUSION_GAP_DETECTED' }
}
