/// Technical metrics to track "Scientific Productivity" on-chain.
pub fn calculate_impact_score(count: u64, total_severity: u64) -> u64 {
    if count == 0 { 0 }
    else { 
        //Impact is count weighted by average severity
        (count * total_severity) / 10 
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

#[starknet::interface]
pub trait IStatistics<TContractState> {
    fn get_domain_impact(self: @TContractState, domain: felt252) -> u64;
    fn get_collaboration_index(self: @TContractState) -> u16;
    fn get_total_verified_records(self: @TContractState) -> u64;
}
