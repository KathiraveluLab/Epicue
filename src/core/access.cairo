use starknet::ContractAddress;

#[starknet::interface]
pub trait IAccessControl<TContractState> {
    fn add_authority(ref self: TContractState, new_authority: ContractAddress);
    fn is_authority(self: @TContractState, address: ContractAddress) -> bool;
}

/// Helper to assert caller is an authority.
pub fn assert_is_authority(is_auth: bool) {
    assert(is_auth, 'Caller not authority');
}
