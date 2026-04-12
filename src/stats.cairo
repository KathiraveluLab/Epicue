/// Normalization constant for EQUISYS Impact Score
pub const KAPPA: u64 = 10;

/// Technical metrics to track "Scientific Productivity" on-chain.
/// Defined in Section 7.1 as: (count * aggregate_severity) / KAPPA
pub fn calculate_impact_score(count: u64, total_severity: u64) -> u64 {
    if count == 0 { 0 }
    else { 
        (count * total_severity) / KAPPA 
    }
}

pub fn calculate_collaboration_index(auth_count: u64, record_count: u64) -> u16 {
    if record_count == 0 { 0 }
    else {
        // Higher unique authorities per record indicates better inter-institutional collaboration
        let index = (auth_count * 100) / record_count;
        index.try_into().unwrap_or(100)
    }
}

/// New analytical metric for interdisciplinary density
pub fn calculate_domain_density(domain_count: u64, total_count: u64) -> u16 {
    if total_count == 0 { return 0; }
    let density = (domain_count * 100) / total_count;
    density.try_into().unwrap_or(0)
}

/// Institutional Integrity Score based on historical disputes
pub fn calculate_integrity_score(success_rate: u8, age: u64) -> u64 {
    (success_rate.into() * 10) + (age / 1000)
}

#[starknet::interface]
pub trait IStatistics<TContractState> {
    fn get_domain_impact(self: @TContractState, domain: felt252) -> u64;
    fn get_collaboration_index(self: @TContractState) -> u16;
    fn get_total_verified_records(self: @TContractState) -> u64;
}
