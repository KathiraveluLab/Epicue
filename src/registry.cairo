#[starknet::interface]
pub trait IRegistry<TContractState> {
    fn submit_record(ref self: TContractState, user_id: felt252, data_hash: felt252);
    fn get_record(self: @TContractState, user_id: felt252) -> felt252;
}

#[starknet::contract]
mod Registry {
    use starknet::get_caller_address;
    use starknet::ContractAddress;
    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess};

    #[storage]
    struct Storage {
        records: Map<felt252, felt252>,
        authorities: Map<ContractAddress, bool>,
    }

    #[constructor]
    fn constructor(ref self: ContractState, initial_authority: ContractAddress) {
        self.authorities.write(initial_authority, true);
    }

    #[abi(embed_v0)]
    impl RegistryImpl of super::IRegistry<ContractState> {
        fn submit_record(ref self: ContractState, user_id: felt252, data_hash: felt252) {
            let caller = get_caller_address();
            assert(self.authorities.read(caller), 'Unauthorized submission');
            self.records.write(user_id, data_hash);
        }

        fn get_record(self: @ContractState, user_id: felt252) -> felt252 {
            self.records.read(user_id)
        }
    }

    #[external(v0)]
    fn add_authority(ref self: ContractState, new_authority: ContractAddress) {
        let caller = get_caller_address();
        assert(self.authorities.read(caller), 'Caller not authority');
        self.authorities.write(new_authority, true);
    }
}
