/// Generalized record submitted for Epicue use cases.
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

/// Specialized Water Quality record.
#[derive(Drop, Serde, starknet::Store)]
pub struct WaterRecord {
    pub subject_id: felt252,
    pub potability_ppm: u32,
    pub ph_level: u16,        // Scaled by 100 (e.g., 720 = 7.2)
    pub leak_detected: bool,
    pub timestamp: u64,
}

/// Specialized Industrial Traceability record.
#[derive(Drop, Serde, starknet::Store)]
pub struct IndustrialRecord {
    pub subject_id: felt252,
    pub carbon_emissions_tons: u64,
    pub steel_mill_id: felt252,
    pub audit_passed: bool,
    pub timestamp: u64,
}

/// Specialized Higher Education record.
#[derive(Drop, Serde, starknet::Store)]
pub struct EducationRecord {
    pub subject_id: felt252,
    pub integrity_index: u8,
    pub inclusion_score: u8,
    pub academic_year: u16,
    pub timestamp: u64,
}
