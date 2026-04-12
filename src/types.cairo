/// Generalized record submitted for EQUISYS use cases.
#[derive(Drop, Serde, starknet::Store)]
pub struct EpicueRecord {
    pub subject_id: felt252,
    pub domain: felt252,
    pub category: felt252,
    pub severity: u8,
    pub timestamp: u64,
    pub data_hash: felt252,
}

/// Legacy healthcare record structure.
#[derive(Drop, Serde, starknet::Store)]
pub struct HealthRecord {
    pub patient_id: felt252,
    pub service_category: felt252,
    pub severity: u8,
    pub timestamp: u64,
    pub data_hash: felt252,
}

pub mod domains {
    pub const HEALTHCARE: felt252 = 'healthcare';
    pub const WATER: felt252 = 'water';
    pub const INDUSTRY: felt252 = 'industry';
}
