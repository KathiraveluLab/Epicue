/// The Governor (Accountability)
/// Manages system-wide compliance and authority delegation as defined in Epicue Triad.

use starknet::ContractAddress;

#[derive(Drop, Serde, starknet::Store)]
pub struct GovernanceAction {
    pub actor: ContractAddress,
    pub target: ContractAddress,
    pub action_type: felt252, // 'ADD_AUTH', 'REMOVE_AUTH'
    pub timestamp: u64,
}

pub mod actions {
    pub const ADD_AUTHORITY: felt252 = 'ADD_AUTH';
    pub const REMOVE_AUTHORITY: felt252 = 'REMOVE_AUTH';
    pub const SET_REPUTATION_FLOOR: felt252 = 'SET_FLOOR';
}

/// FATE Compliance Score (Section 2.3)
/// A STARK-proved metric based on authority density and report volume.
pub fn calculate_fate_score(record_count: u64, auth_count: u64) -> u8 {
    let mut score = 40_u8; // Base baseline
    
    // Volumetric Performance (Transparency)
    if record_count > 500 { score += 30; }
    else if record_count > 100 { score += 20; }
    else if record_count > 10 { score += 10; }
    
    // Authority Density (Accountability)
    // Optimal density: 1 authority per 50 records
    if auth_count > 0 {
        let density = record_count / auth_count;
        if density >= 10 && density <= 100 {
            score += 30;
        } else if density > 100 {
            score += 10; // Under-governed
        }
    }
    
    if score > 100 { 100 } else { score }
}

pub fn get_compliance_label(score: u8) -> felt252 {
    if score >= 90 { 'EPICUE_EXCELLENT' }
    else if score >= 70 { 'EPICUE_GOOD' }
    else if score >= 50 { 'EPICUE_AVERAGE' }
    else { 'EPICUE_REVIEW_REQUIRED' }
}

/// ── Governance Voting Logic ──────────────────────────────────────────────────

#[derive(Drop, Serde, starknet::Store)]
pub struct Proposal {
    pub id: u64,
    pub proposer: ContractAddress,
    pub target: ContractAddress,
    pub action_type: felt252, // 'ADD_AUTH', 'REMOVE_AUTH'
    pub votes_for: u64,
    pub votes_against: u64,
    pub status: felt252, // 'PENDING', 'APPROVED', 'REJECTED'
    pub end_block: u64,
}

pub mod proposal_status {
    pub const PENDING: felt252 = 'PENDING';
    pub const APPROVED: felt252 = 'APPROVED';
    pub const REJECTED: felt252 = 'REJECTED';
}

/// Calculate the required votes for a proposal to pass.
/// Quorum logic: 50% of authorities + 1
pub fn get_quorum_threshold(authority_count: u64) -> u64 {
    (authority_count / 2) + 1
}

pub fn is_finalizable(proposal: @Proposal, authority_count: u64) -> bool {
    let threshold = get_quorum_threshold(authority_count);
    let total_votes = *proposal.votes_for + *proposal.votes_against;
    total_votes >= threshold
}

/// Advanced Governance Primitives for "Sustainable Societies"
#[derive(Drop, Serde, starknet::Store)]
pub struct VetoPower {
    pub domain: felt252,
    pub threshold: u8,
    pub active_vetos: u8,
}

pub fn can_be_vetoed(proposal: @Proposal, veto: VetoPower) -> bool {
    if veto.active_vetos >= veto.threshold {
        return true;
    }
    false
}

/// Emergency Stop for a compromised domain case-study
pub fn calculate_emergency_quorum(total_members: u16) -> u16 {
    // Emergency requires 2/3 majority
    (total_members.into() * 2) / 3
}

/// Verifies if a proposal is "Scientifically Sound" based on reviewer data
pub fn is_scientifically_sound(consensus_avg: u8) -> bool {
    consensus_avg >= 70
}

/// Weighted Delegation for Inter-Institutional Collaboration
#[derive(Drop, Serde, starknet::Store)]
pub struct VoteWeight {
    pub institution: ContractAddress,
    pub weight: u16,
}

pub fn calculate_weighted_vote(votes: u64, weight: u16) -> u64 {
    (votes * weight.into()) / 100
}

pub fn check_veto_expiry(veto_block: u64, current_block: u64) -> bool {
    current_block > veto_block + 5000 // Verification period 
}
