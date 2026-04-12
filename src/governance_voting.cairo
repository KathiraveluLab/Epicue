use starknet::ContractAddress;

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
    *proposal.votes_for >= threshold || *proposal.votes_against >= threshold
}
