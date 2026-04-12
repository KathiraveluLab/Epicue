use starknet::ContractAddress;

#[derive(Drop, Serde, starknet::Store)]
pub struct DataSchema {
    pub domain: felt252,
    pub version: u16,
    pub field_count: u8,
    pub is_deprecated: bool,
    pub authority: ContractAddress,
}

pub mod schema_types {
    pub const NUMERIC: u8 = 1;
    pub const CATEGORICAL: u8 = 2;
    pub const GEOSPATIAL: u8 = 3;
    pub const BYTES32: u8 = 4;
}

pub fn validate_record_against_schema(schema: DataSchema, record_fields: u8) -> bool {
    if schema.is_deprecated { return false; }
    if record_fields != schema.field_count { return false; }
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
    }
}

/// Inter-institutional schema mapping logic
pub fn map_external_schema(domain: felt252, external_org_id: felt252) -> u64 {
    // Return a unique registry ID for the mapped schema
    (domain.into() + external_org_id.into())
}
