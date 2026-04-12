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
    else if domain == domains::EDUCATION { 'Higher Education' }
    else { 'Unknown Domain' }
}

pub fn get_default_domain_desc(domain: felt252) -> felt252 {
    if domain == domains::HEALTHCARE { 'Patient efficacy & care reports' }
    else if domain == domains::WATER { 'Potability & leak alerts' }
    else if domain == domains::INDUSTRY { 'Steel mill audit & carbon trace' }
    else if domain == domains::EDUCATION { 'Academic integrity & inclusion' }
    else { 'Project metadata pending' }
}

pub fn get_fate_pillar_desc(pillar: felt252) -> felt252 {
    if pillar == 'Fairness' { 
        'Equitable L2 access for all' 
    } else if pillar == 'Accountability' { 
        'STARK-proven accountability' 
    } else if pillar == 'Transparency' { 
        'Verifiable Cairo logic' 
    } else if pillar == 'Ethics' { 
        'Privacy with subject consent' 
    } else { 
        'FATE compliance verified' 
    }
}

pub fn get_long_domain_desc(domain: felt252) -> felt252 {
    if domain == domains::HEALTHCARE {
        'Verifiable healthcare reports'
    } else if domain == domains::WATER {
        'On-chain water monitoring'
    } else if domain == domains::GEOSPATIAL {
        'STARK-based spatial proofs'
    } else {
        'EQUISYS framework research'
    }
}

/// Verification context for inter-institutional collaboration
pub fn get_collaboration_justification(auth_count: u64) -> felt252 {
    if auth_count > 5 {
        'Scientific consensus reached'
    } else {
        'Multi-authority audit phase'
    }
}
