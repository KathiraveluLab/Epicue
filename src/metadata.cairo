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
        'Equitable L2 access for all societal strata.' 
    } else if pillar == 'Accountability' { 
        'STARK-proven institutional data accountability.' 
    } else if pillar == 'Transparency' { 
        'Verifiable Cairo logic and open public service registries.' 
    } else if pillar == 'Ethics' { 
        'Privacy-preserving blinded identifiers with subject consent.' 
    } else { 
        'FATE compliance verified across all domains.' 
    }
}

pub fn get_long_domain_desc(domain: felt252) -> felt252 {
    if domain == domains::HEALTHCARE {
        'Verifiable healthcare reporting for equity in fetal health monitoring.'
    } else if domain == domains::WATER {
        'On-chain water quality monitoring for sustainable sanitation audits.'
    } else if domain == domains::GEOSPATIAL {
        'Integrating natural science data models with STARK-based spatial proofs.'
    } else {
        'Interdisciplinary research study within the EQUISYS framework.'
    }
}

/// Verification context for inter-institutional collaboration
pub fn get_collaboration_justification(auth_count: u64) -> felt252 {
    if auth_count > 5 {
        'Broad inter-institutional scientific consensus established.'
    } else {
        'Initial multi-authority collaborative audit phase.'
    }
}
