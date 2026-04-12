use epicue_core::types::domains;

#[derive(Drop, Serde, starknet::Store)]
pub struct DomainMetadata {
    pub name: felt252,
    pub description: felt252,      // Short description tag
    pub long_description: felt252, // Multi-felt description if needed (simplified here)
}

#[starknet::interface]
pub trait IMetadata<TContractState> {
    fn get_domain_name(self: @TContractState, domain: felt252) -> felt252;
    fn get_domain_description(self: @TContractState, domain: felt252) -> felt252;
    fn get_pillar_description(self: @TContractState, pillar: felt252) -> felt252;
}

pub fn get_default_domain_name(domain: felt252) -> felt252 {
    if domain == domains::HEALTHCARE { 'Healthcare' }
    else if domain == domains::WATER { 'Water Quality' }
    else if domain == domains::INDUSTRY { 'Industrial Traceability' }
    else { 'Unknown Domain' }
}

pub fn get_default_domain_desc(domain: felt252) -> felt252 {
    if domain == domains::HEALTHCARE { 'Patient efficacy & care reports' }
    else if domain == domains::WATER { 'Potability & leak alerts' }
    else if domain == domains::INDUSTRY { 'Steel mill audit & carbon trace' }
    else { 'Project metadata pending' }
}

pub fn get_fate_pillar_desc(pillar: felt252) -> felt252 {
    if pillar == 'Fairness' { 'Equitable L2 access costs' }
    else if pillar == 'Accountability' { 'STARK-proved state changes' }
    else if pillar == 'Transparency' { 'Publicly auditable Cairo logic' }
    else if pillar == 'Ethics' { 'No PII stored on-chain' }
    else { 'FATE compliance verified' }
}
