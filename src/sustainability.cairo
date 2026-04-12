use starknet::ContractAddress;

#[derive(Drop, Serde, starknet::Store)]
pub struct SustainabilityRecord {
    pub institution: ContractAddress,
    pub carbon_metric: u64,     // CO2 offset in kg
    pub energy_efficiency: u8,  // Percentage (0-100)
    pub waste_reduction: u8,    // Percentage (0-100)
    pub report_index: u64,
    pub timestamp: u64,
}

/// Calculate the incremental Green Stature gain for a report
pub fn calculate_green_stature_gain(carbon: u64, efficiency: u8, waste: u8) -> u64 {
    let efficiency_weight = efficiency.into() * 2;
    let waste_weight = waste.into() * 2;
    (carbon / 100) + efficiency_weight + waste_weight
}

/// Validate if a report meets the Manufacturing Domain Benchmark (Section 9.2)
pub fn validate_industry_benchmark(carbon: u64, efficiency: u8) -> bool {
    // Basic threshold for "Steel Mills" sector
    if carbon < 100 { return false; }
    if efficiency < 40 { return false; }
    true
}

pub fn get_sustainability_label(green_stature: u64) -> felt252 {
    if green_stature > 10000 { 'NET_ZERO_LEADER' }
    else if green_stature > 5000 { 'ECO_CHAMPION' }
    else if green_stature > 1000 { 'SUSTAINABLE_ACTOR' }
    else { 'CARBON_INTENSIVE' }
}
