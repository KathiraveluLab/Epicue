use starknet::ContractAddress;

#[derive(Drop, Serde, starknet::Store)]
pub struct MethodologyGuideline {
    pub id: u64,
    pub title: felt252,
    pub author: ContractAddress,
    pub domain: felt252,
    pub content_hash: felt252, // IPFS or similar link
    pub version: u16,
    pub timestamp: u64,
    pub impact_metric: u64, // Weighted scientific visibility
}

/// Verification Logic for Research Methodology (Section 8 of Paper)
pub fn validate_methodology_integrity(version: u16, title: felt252) -> bool {
    if version == 0 { return false; }
    if title == 0 { return false; }
    true
}

/// Calculate Scientific Visibility based on domain impact
pub fn calculate_scientific_visibility(domain_impact: u64) -> u64 {
    // Guidelines in high-impact domains receive a boost in visibility
    (domain_impact * 15) / 10
}

pub fn get_methodology_status(version: u16) -> felt252 {
    if version == 1 { 'DRAFT' }
    else if version < 5 { 'PEER_REVIEWED' }
    else { 'ESTABLISHED_STANDARD' }
}
