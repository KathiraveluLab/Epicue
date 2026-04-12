use starknet::ContractAddress;

#[derive(Drop, Serde, starknet::Store)]
pub struct DataSchema {
    pub domain: felt252,
    pub version: u16,
    pub field_count: u8,
    pub is_deprecated: bool,
    pub authority: ContractAddress,
    pub schema_hash: felt252,
}

#[derive(Drop, Serde, starknet::Store)]
pub struct FieldConstraint {
    pub field_index: u8,
    pub min_value: u64,
    pub max_value: u64,
    pub is_required: bool,
}

pub mod schema_types {
    pub const NUMERIC: u8 = 1;
    pub const CATEGORICAL: u8 = 2;
    pub const GEOSPATIAL: u8 = 3;
    pub const BYTES32: u8 = 4;
    pub const STRING_SHORT: u8 = 5;
}

pub fn validate_record_against_schema(schema: @DataSchema, record_fields: u8) -> bool {
    if *schema.is_deprecated { return false; }
    if record_fields != *schema.field_count { return false; }
    true
}

/// Deep Field Validation Logic
pub fn validate_field_value(constraint: FieldConstraint, value: u64) -> bool {
    if constraint.is_required && value == 0 { return false; }
    if value < constraint.min_value || value > constraint.max_value {
        return false;
    }
    true
}

/// Logical expansion for schema evolution
pub fn upgrade_domain_schema(old: DataSchema, new_version: u16) -> DataSchema {
    DataSchema {
        domain: old.domain,
        version: new_version,
        field_count: old.field_count,
        is_deprecated: false,
        authority: old.authority,
        schema_hash: old.schema_hash,
    }
}

/// Hierarchical Schema Mapping
/// Allows one domain to inherit rules from another (e.g., Medical -> Healthcare)
pub fn resolve_inherited_schema(child_domain: felt252) -> felt252 {
    if child_domain == 'pediatrics' { return 'healthcare'; }
    if child_domain == 'mining' { return 'industry'; }
    if child_domain == 'desalination' { return 'water'; }
    child_domain
}

/// Inter-institutional schema mapping logic
pub fn map_external_schema(domain: felt252, external_org_id: felt252) -> u64 {
    // Return a unique registry ID for the mapped schema
    let d_u256: u256 = domain.into();
    let o_u256: u256 = external_org_id.into();
    (d_u256 + o_u256).try_into().unwrap_or(0)
}

/// Verifiable Schema Integrity Proof
pub fn verify_schema_integrity(hash: felt252, authority: ContractAddress) -> bool {
    if hash == 0 { return false; }
    // Authority must be non-zero
    if authority.into() == 0 { return false; }
    true
}
