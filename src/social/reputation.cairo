use starknet::ContractAddress;

#[derive(Drop, Serde, starknet::Store)]
pub struct InstitutionReputation {
    pub institution: ContractAddress,
    pub reputation_credits: u64,
    pub last_activity_timestamp: u64,
    pub trust_multiplier: u8, // Higher multiplier for longer-term accurate data
    pub bounty_credits: u64, // Rewards for byzantine fault detection
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

/// Awards bounty credits to auditors who successfully flag byzantine behavior
pub fn calculate_bounty_reward(severity: u8, impact: u64) -> u64 {
    (severity.into() * 50) + (impact / 100)
}

/// Penalizes a node for byzantine behavior by reducing reputation based on severity
pub fn apply_graded_slashing(ref reputation: InstitutionReputation, severity: u8) {
    if severity == 3 { // CRITICAL
        reputation.reputation_credits = 0;
        reputation.trust_multiplier = 1;
    } else if severity == 2 { // MAJOR
        reputation.reputation_credits = (reputation.reputation_credits * 50) / 100;
        reputation.trust_multiplier = 1;
    } else if severity == 1 { // MINOR
        reputation.reputation_credits = (reputation.reputation_credits * 75) / 100;
        if reputation.trust_multiplier > 1 {
            reputation.trust_multiplier -= 1;
        }
    }
}

pub mod reputation_tiers {
    pub const BRONZE: u64 = 100;
    pub const SILVER: u64 = 500;
    pub const GOLD: u64 = 1000;
}
