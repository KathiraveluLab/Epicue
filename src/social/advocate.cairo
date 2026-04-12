use starknet::ContractAddress;

#[derive(Drop, Serde, starknet::Store)]
pub struct Advocate {
    pub address: ContractAddress,
    pub name: felt252,
    pub is_active: bool,
    pub records_assisted: u64,
}

/// Checks if an address is a registered and active Digital Inclusion Advocate.
pub fn is_vetted_advocate(address: ContractAddress) -> bool {
    // In a full implementation, this would check a storage map.
    // For the initial prototype, we assume the system will track this.
    true
}

pub mod advocate_actions {
    pub const REGISTER: felt252 = 'REGISTER_ADV';
    pub const REVOKE: felt252 = 'REVOKE_ADV';
}
