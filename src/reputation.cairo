use starknet::ContractAddress;

#[derive(Drop, Serde, starknet::Store)]
pub struct InstitutionReputation {
    pub institution: ContractAddress,
    pub reputation_credits: u64,
    pub last_activity_timestamp: u64,
    pub trust_multiplier: u8, // Higher multiplier for longer-term accurate data
}

pub fn calculate_credit_gain(severity: u8, domain: felt252) -> u64 {
    // Basic incentive logic: higher severity data earns more reputation credits
    // This rewards "high-value" contributions to the registry
    (severity.into() * 10)
}

/// Incentivizes "Net Zero" achievements by awarding significant credit gains
pub fn calculate_sustainability_bonus(green_stature: u64) -> u64 {
    green_stature / 50
}

pub mod reputation_tiers {
    pub const BRONZE: u64 = 100;
    pub const SILVER: u64 = 500;
    pub const GOLD: u64 = 1000;
}
