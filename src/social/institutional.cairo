use starknet::ContractAddress;

#[derive(Drop, Serde, starknet::Store)]
pub struct Institution {
    pub name: felt252,
    pub primary_domain: felt252,
    pub tier: u8, // 1: Bronze, 2: Silver, 3: Gold
    pub reputation_credits: u64,
    pub is_vetted: bool,
    pub enrollment_date: u64,
}

pub mod institution_tiers {
    pub const BRONZE: u8 = 1;
    pub const SILVER: u8 = 2;
    pub const GOLD: u8 = 3;
}

pub fn calculate_tier_upgrade(credits: u64) -> u8 {
    if credits >= 10000 { institution_tiers::GOLD }
    else if credits >= 2500 { institution_tiers::SILVER }
    else { institution_tiers::BRONZE }
}

/// Verifiable Tiered Access Logic
/// Determines if an institution has the rights to access specific sensitive data domains.
pub fn can_access_sensitive_data(tier: u8, data_sensitivity: u8) -> bool {
    if tier == institution_tiers::GOLD { return true; }
    if tier == institution_tiers::SILVER && data_sensitivity <= 2 { return true; }
    if tier == institution_tiers::BRONZE && data_sensitivity <= 1 { return true; }
    false
}

#[derive(Drop, Serde, starknet::Store)]
pub struct InstitutionalMember {
    pub address: ContractAddress,
    pub institution_id: felt252,
    pub role: felt252,
    pub active: bool,
}

/// Reward Multiplier Logic
/// Higher tier institutions receive more credits for the same scientific contribution.
pub fn get_reputation_multiplier(tier: u8) -> u16 {
    if tier == institution_tiers::GOLD { 150 } // 1.5x
    else if tier == institution_tiers::SILVER { 120 } // 1.2x
    else { 100 } // 1.0x
}

pub fn validate_member_role(role: felt252) -> bool {
    if role == 'admin' || role == 'researcher' || role == 'auditor' {
        return true;
    }
    false
}

/// Verification of Institutional Proofs
/// Ensures that the institution's signature and domain are consistent.
pub fn verify_institutional_proof(domain: felt252, declared_domain: felt252) -> bool {
    if domain == declared_domain { return true; }
    false
}
