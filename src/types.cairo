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
    pub const EDUCATION: felt252 = 'education';
    pub const GEOSPATIAL: felt252 = 'geospatial';
    pub const GEOLOGY: felt252 = 'geology';
}

/// Specialized Natural Science record for Geology.
#[derive(Drop, Serde, starknet::Store)]
pub struct GeologicalRecord {
    pub subject_id: felt252,
    pub latitude: i32,  // Fixed point: deg * 100
    pub longitude: i32, // Fixed point: deg * 100
    pub sample_depth: u32,
    pub mineral_density: u16,
    pub timestamp: u64,
}
