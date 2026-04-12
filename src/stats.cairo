#[starknet::interface]
pub trait IStatistics<TContractState> {
    fn get_domain_count(self: @TContractState, domain: felt252) -> u64;
    fn get_total_verified_records(self: @TContractState) -> u64;
}
