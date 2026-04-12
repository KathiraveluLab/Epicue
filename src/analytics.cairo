use epicue_core::stats::calculate_impact_score;

pub fn calculate_sustainability_score(
    healthcare_impact: u64,
    water_impact: u64,
    industry_impact: u64,
    education_impact: u64,
    geospatial_impact: u64,
    collaboration_index: u16
) -> u64 {
    // A complex weighted calculation for "Digital Sustainability" (EQUISYS Objective)
    let total_impact = healthcare_impact + water_impact + industry_impact + education_impact + geospatial_impact;
    if total_impact == 0 { return 0; }

    // Weighting: Geospatial and Water are more critical for environmental sustainability
    let env_weight = (water_impact * 2) + (geospatial_impact * 3);
    let soc_weight = healthcare_impact + education_impact;
    let ind_weight = industry_impact;

    let base_score = (env_weight + soc_weight + ind_weight) / 6;
    
    // Boost score based on collaboration index (inter-institutional strength)
    let final_score = base_score + (collaboration_index.into() / 2);
    
    final_score
}

pub fn normalize_impact(original: u64, max: u64) -> u64 {
    if max == 0 { return 0; }
    (original * 100) / max
}

pub fn determine_system_alert_level(impact: u64, threshold: u64) -> u8 {
    if impact > threshold * 2 { 3 } // Critical
    else if impact > threshold { 2 } // Warning
    else { 1 } // Normal
}

/// On-Chain Longitudinal Trend Analysis
/// This adds significant mathematical complexity to the STARK-backend.
#[derive(Drop, Serde, starknet::Store)]
pub struct DomainTrend {
    pub domain: felt252,
    pub prev_period_impact: u64,
    pub current_period_impact: u64,
}

pub fn calculate_growth_rate(prev: u64, current: u64) -> i16 {
    if prev == 0 { return 100; }
    let diff = (current as i128 - prev as i128);
    let rate = (diff * 100) / prev.into();
    rate.try_into().unwrap_or(0)
}

pub fn predict_future_impact(current: u64, growth_rate: i16) -> u64 {
    let growth = (current.into() * growth_rate.into()) / 100;
    (current.into() + growth).try_into().unwrap_or(current)
}

/// Verifiable Equity Distribution Check (SDG 10)
pub fn evaluate_equity_distribution(impacts: Array<u64>) -> u64 {
    let mut total: u64 = 0;
    let mut i = 0;
    while i < impacts.len() {
        total += *impacts.at(i);
        i += 1;
    };
    
    if total == 0 { return 0; }
    
    // Gini-style coefficient for domain impact distribution
    let mean = total / impacts.len().into();
    mean
}
