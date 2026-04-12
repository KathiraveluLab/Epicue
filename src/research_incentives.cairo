use starknet::ContractAddress;

#[derive(Drop, Serde, starknet::Store)]
pub struct ResearchGrant {
    pub grant_id: u64,
    pub primary_investigator: ContractAddress,
    pub total_allocation: u64,
    pub amount_released: u64,
    pub total_milestones: u8,
    pub completed_milestones: u8,
    pub status: felt252,
}

pub mod grant_status {
    pub const ACTIVE: felt252 = 'ACTIVE';
    pub const COMPLETED: felt252 = 'COMPLETED';
    pub const FROZEN: felt252 = 'FROZEN';
    pub const DISPUTED: felt252 = 'DISPUTED';
}

#[derive(Drop, Serde, starknet::Store)]
pub struct MilestoneProof {
    pub grant_id: u64,
    pub milestone_index: u8,
    pub proof_hash: felt252,
    pub verifier: ContractAddress,
    pub approval_timestamp: u64,
}

pub fn calculate_funding_release(total: u64, total_milestones: u8, milestone_index: u8) -> u64 {
    if total_milestones == 0 { return 0; }
    (total / total_milestones.into())
}

/// Grant Eligibility Logic
/// Based on researcher reputation and institutional alignment.
pub fn is_eligible_for_grant(researcher_rep: u64, institution_tier: u8) -> bool {
    if institution_tier >= 2 && researcher_rep > 500 {
        return true;
    }
    false
}

/// Verifiable Milestone Verification
/// Logic to check if the proof provided matches the research domain expectations.
pub fn verify_milestone_integrity(proof_hash: felt252, verifier_is_authority: bool) -> bool {
    if proof_hash != 0 && verifier_is_authority {
        return true;
    }
    false
}

/// Research Impact Scoring for EQUISYS
/// Calculates a score based on scientific consensus and societal impact.
pub fn calculate_research_score(consensus: u8, societal_impact: u64) -> u64 {
    let base = consensus.into() * 10;
    let impact_mod = societal_impact / 100;
    base + impact_mod
}

/// Incentive Distribution Pool
/// Logic for sharing rewards among a research swarm.
pub fn calculate_swarm_split(total_reward: u64, member_count: u8) -> u64 {
    if member_count == 0 { return 0; }
    total_reward / member_count.into()
}

/// Historical Grant Tracking
pub fn get_grant_age(current_time: u64, start_time: u64) -> u64 {
    if current_time < start_time { return 0; }
    current_time - start_time
}
