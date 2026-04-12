use epicue_core::types::domains;

#[starknet::interface]
pub trait IValidation<TContractState> {
    fn validate_report_severity(self: @TContractState, domain: felt252, severity: u8) -> bool;
}

pub fn check_domain_constraints(domain: felt252, category: felt252, severity: u8) {
    // Integrity check: severity must be within bounds for all domains
    assert(severity >= 1_u8 && severity <= 5_u8, 'Severity scale: 1-5');

    // Domain-specific logic
    if domain == domains::WATER {
        // Water quality reports below severity 2 might be routine audits
        if severity >= 4_u8 {
            // High priority water issues must have specific category
            assert(category != 'routine_check', 'Critical must not be routine');
        }
    } else if domain == domains::INDUSTRY {
        // Industry audits for carbon footprint are usually higher severity if out of spec
        if category == 'carbon_footprint' {
            assert(severity >= 2_u8, 'Carbon report minimum priority');
        }
    } else if domain == domains::EDUCATION {
        // Academic integrity reports must be at least severity 3
        if category == 'academic_integrity' {
            assert(severity >= 3_u8, 'Integrity report min priority');
        }
    }
}
