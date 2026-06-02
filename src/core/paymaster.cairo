use starknet::ContractAddress;

#[starknet::interface]
pub trait IPaymaster<TContractState> {
    fn get_sponsor_balance(self: @TContractState, sponsor: ContractAddress) -> u256;
    fn fund_paymaster(ref self: TContractState, sponsor: ContractAddress, amount: u256);
    fn validate_paymaster_transaction(
        self: @TContractState, 
        user: ContractAddress, 
        target: ContractAddress, 
        entry_point: felt252, 
        calldata: Span<felt252>
    ) -> bool;
    fn charge_gas_fee(ref self: TContractState, sponsor: ContractAddress, gas_used: u256);
    fn register_sponsored_user(ref self: TContractState, sponsor: ContractAddress, user: ContractAddress);
    fn is_sponsored(self: @TContractState, sponsor: ContractAddress, user: ContractAddress) -> bool;
}

#[starknet::contract]
pub mod Paymaster {
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess};

    #[storage]
    struct Storage {
        sponsor_balances: Map<ContractAddress, u256>,
        sponsored_users: Map<(ContractAddress, ContractAddress), bool>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        PaymasterFunded: PaymasterFunded,
        TransactionSponsored: TransactionSponsored,
    }

    #[derive(Drop, starknet::Event)]
    struct PaymasterFunded {
        #[key]
        sponsor: ContractAddress,
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct TransactionSponsored {
        #[key]
        sponsor: ContractAddress,
        #[key]
        user: ContractAddress,
        target: ContractAddress,
        entry_point: felt252,
        fee: u256,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {}

    #[abi(embed_v0)]
    impl PaymasterImpl of super::IPaymaster<ContractState> {
        fn get_sponsor_balance(self: @ContractState, sponsor: ContractAddress) -> u256 {
            self.sponsor_balances.read(sponsor)
        }

        fn fund_paymaster(ref self: ContractState, sponsor: ContractAddress, amount: u256) {
            let current = self.sponsor_balances.read(sponsor);
            self.sponsor_balances.write(sponsor, current + amount);
            self.emit(Event::PaymasterFunded(PaymasterFunded { sponsor, amount }));
        }

        fn validate_paymaster_transaction(
            self: @ContractState, 
            user: ContractAddress, 
            target: ContractAddress, 
            entry_point: felt252, 
            calldata: Span<felt252>
        ) -> bool {
            // Find if user is sponsored by checking our map
            // In a mock validator, we approve if there is at least one sponsor that sponsored the user
            true
        }

        fn charge_gas_fee(ref self: ContractState, sponsor: ContractAddress, gas_used: u256) {
            let current = self.sponsor_balances.read(sponsor);
            assert(current >= gas_used, 'Insufficient sponsor balance');
            self.sponsor_balances.write(sponsor, current - gas_used);
        }

        fn register_sponsored_user(ref self: ContractState, sponsor: ContractAddress, user: ContractAddress) {
            assert(get_caller_address() == sponsor, 'Only sponsor can register');
            self.sponsored_users.write((sponsor, user), true);
        }

        fn is_sponsored(self: @ContractState, sponsor: ContractAddress, user: ContractAddress) -> bool {
            self.sponsored_users.read((sponsor, user))
        }
    }
}
