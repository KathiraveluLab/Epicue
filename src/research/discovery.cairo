use starknet::ContractAddress;

#[derive(Drop, Serde, starknet::Store)]
pub struct ResearchDiscovery {
    pub domain: felt252,
    pub lead_researcher: ContractAddress,
    pub publication_hash: felt252,
    pub impact_threshold: u64,
    pub metadata_uri: felt252,
}

pub fn filter_high_impact_domains(
    domains: Array<felt252>, 
    impacts: Array<u64>, 
    threshold: u64
) -> Array<felt252> {
    let mut high_impact = array![];
    let mut i = 0;
    while i < domains.len() {
        if *impacts.at(i) >= threshold {
            high_impact.append(*domains.at(i));
        }
        i += 1;
    };
    high_impact
}

/// Logical expansion for interdisciplinary search
pub fn map_research_tags(domain: felt252) -> Array<felt252> {
    if domain == 'healthcare' {
        return array!['fetal_health', 'equity', 'access'];
    } else if domain == 'water' {
        return array!['sustainable_sanitation', 'l1_data', 'ecology'];
    } else {
        return array!['equisys', 'general_research'];
    }
}

pub fn calculate_scientific_relevance(
    citation_count: u64, 
    reputation: u64
) -> u64 {
    (citation_count * 10) + (reputation / 100)
}
