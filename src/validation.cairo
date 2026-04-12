/// The Validator (System Integrity)
/// Enforces business rules and geospatial boundaries as defined in EQUISYS Triad.

use epicue_core::types::domains;

#[starknet::interface]
pub trait IValidation<TContractState> {
    fn validate_report_severity(self: @TContractState, domain: felt252, severity: u8) -> bool;
}

pub fn check_domain_constraints(domain: felt252, category: felt252, severity: u8) {
    // Integrity check: severity must be within bounds for all domains
    assert(severity >= 1_u8 && severity <= 5_u8, 'Severity scale: 1-5');

    // Domain-specific logic mapping to Section 10 of the paper
    if domain == domains::WATER {
        // High priority water issues must have specific category
        if severity >= 4_u8 {
            assert(category != 'routine_check', 'Critical must not be routine');
        }
    } else if domain == domains::INDUSTRY {
        // Industry audits for carbon footprint are usually higher severity if out of spec
        if category == 'carbon_footprint' {
            assert(severity >= 2_u8, 'Carbon report minimum priority');
        }
    } else if domain == domains::EDUCATION {
        // Academic integrity reports must meet Section 2.1 threshold
        if category == 'academic_integrity' {
            assert(severity >= 3_u8, 'Integrity report min priority');
        }
    } else if domain == domains::GEOSPATIAL {
        assert(severity <= 5_u8, 'Invalid geo severity');
    }
}

/// Verifiable Geo-fencing Pattern (Section 9)
/// Ensures research data originates from STARK-verified sites.
pub fn check_geospatial_bounds(lat: i32, lon: i32) {
    // Primary Site: EQUISYS Research Zone Alpha
    let is_in_zone_alpha = lat >= 4000 && lat <= 4200 && lon >= -7500 && lon <= -7300;
    // Secondary Site: EQUISYS Research Zone Beta
    let is_in_zone_beta = lat >= 1000 && lat <= 1200 && lon >= 3000 && lon <= 3200;

    assert(is_in_zone_alpha || is_in_zone_beta, 'Outside geo-fenced research');
}

/// Advanced geological integrity check: Section 9.1
pub fn validate_geological_integrity(depth: u32, density: u16) {
    if depth > 1000 {
        assert(density > 200, 'Density too low for depth');
    }
    // High-density samples require deeper extraction
    if density > 500 {
        assert(depth > 500, 'Unrealistic surface density');
    }
}
