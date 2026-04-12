use starknet::ContractAddress;

#[derive(Drop, Serde, starknet::Store)]
pub struct ReviewSession {
    pub subject_id: felt252,
    pub reviewer: ContractAddress,
    pub is_disputed: bool,
    pub resolution_timestamp: u64,
    pub scientific_consensus: u8, // 0-100 scale
}

pub mod review_status {
    pub const PENDING: u8 = 0;
    pub const VERIFIED: u8 = 1;
    pub const REJECTED: u8 = 2;
    pub const UNDER_REVIEW: u8 = 3;
}

pub fn calculate_consensus_delta(current: u8, new_vote: u8, total_votes: u64) -> u8 {
    if total_votes == 0 { new_vote }
    else {
        let weight = 100 / (total_votes + 1);
        let weighted_current = (current.into() * (100 - weight.into())) / 100;
        let weighted_new = (new_vote.into() * weight.into()) / 100;
        (weighted_current + weighted_new).try_into().unwrap_or(0)
    }
}

pub fn resolve_scientific_dispute(consensus: u8, severity: u8) -> bool {
    // If consensus is low (< 40) for a high severity report (> 4), it remains disputed
    if severity > 4 && consensus < 40 {
        return true;
    }
    false
}

/// Advanced Reviewer Committee Logic
/// This adds significant logic depth for institutional scientific growth.
#[derive(Drop, Serde, starknet::Store)]
pub struct ReviewerCommittee {
    pub domain: felt252,
    pub member_1: ContractAddress,
    pub member_2: ContractAddress,
    pub member_3: ContractAddress,
    pub required_consensus: u8,
}

pub fn verify_review_quorum(
    v1: u8, v2: u8, v3: u8, threshold: u8
) -> (u8, bool) {
    let avg = (v1.into() + v2.into() + v3.into()) / 3;
    let avg_u8: u8 = avg.try_into().unwrap_or(0);
    (avg_u8, avg_u8 >= threshold)
}

/// Penalize an institution for submitting fraudulent data (dispute-driven)
pub fn calculate_reputation_penalty(severity: u8, dispute_intensity: u8) -> u64 {
    let base_penalty = severity.into() * 20;
    let intensity_modifier = dispute_intensity.into() * 5;
    base_penalty + intensity_modifier
}

/// Grant "Senior Researcher" status based on accurate peer reviews
pub fn check_researcher_promotion(successful_reviews: u64, impact_contributed: u64) -> bool {
    if successful_reviews > 10 && impact_contributed > 500 {
        return true;
    }
    false
}
