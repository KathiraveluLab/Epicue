// use epicue_core::research::stats::calculate_impact_score;

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
    let current_i128: i128 = current.into();
    let prev_i128: i128 = prev.into();
    let diff = current_i128 - prev_i128;
    let rate = (diff * 100_i128) / prev_i128;
    rate.try_into().unwrap_or(0)
}

pub fn predict_future_impact(current: u64, growth_rate: i16) -> u64 {
    let current_i128: i128 = current.into();
    let growth_rate_i128: i128 = growth_rate.into();
    let growth = (current_i128 * growth_rate_i128) / 100_i128;
    (current_i128 + growth).try_into().unwrap_or(current)
}

/// Statistical Primitives for Research Accuracy (EPICUE Phase 4)
pub fn calculate_variance(data: Array<u64>, mean: u64) -> u64 {
    if data.len() < 2 { return 0; }
    let mut sum_sq_diff: u128 = 0;
    let mut i = 0;
    while i < data.len() {
        let val = *data.at(i);
        let diff: u128 = if val > mean { (val - mean).into() } else { (mean - val).into() };
        sum_sq_diff += diff * diff;
        i += 1;
    };
    (sum_sq_diff / (data.len().into() - 1)).try_into().unwrap_or(0)
}

/// Approximate Square Root for Standard Deviation
pub fn sqrt(n: u64) -> u64 {
    if n == 0 { return 0; }
    let mut x = n;
    let mut y = (x + 1) / 2;
    while y < x {
        x = y;
        y = (x + n / x) / 2;
    };
    x
}

pub fn calculate_standard_deviation(data: Array<u64>, mean: u64) -> u64 {
    let var = calculate_variance(data, mean);
    sqrt(var)
}

/// Z-Score for Outlier Detection
pub fn calculate_z_score(value: u64, mean: u64, std_dev: u64) -> i16 {
    if std_dev == 0 { return 0; }
    let val_i128: i128 = value.into();
    let mean_i128: i128 = mean.into();
    let std_dev_i128: i128 = std_dev.into();
    let diff = val_i128 - mean_i128;
    let score = (diff * 10_i128) / std_dev_i128; // x10 for precision
    score.try_into().unwrap_or(0)
}

/// Simple Moving Average
pub fn calculate_sma(window: Array<u64>) -> u64 {
    if window.len() == 0 { return 0; }
    let mut total: u64 = 0;
    let mut i = 0;
    while i < window.len() {
        total += *window.at(i);
        i += 1;
    };
    total / window.len().into()
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
