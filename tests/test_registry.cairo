use snforge_std::{declare, ContractClassTrait, start_cheat_caller_address, stop_cheat_caller_address, DeclareResultTrait, DeclareResult};
use epicue_core::registry::{IRegistryDispatcher, IRegistryDispatcherTrait};
use starknet::ContractAddress;
use core::result::ResultTrait;

#[test]
fn test_submit_and_get_record() {
    let declare_result = ResultTrait::unwrap(declare("Registry"));
    let contract = match declare_result {
        DeclareResult::Success(class) => class,
        DeclareResult::AlreadyDeclared(class) => class,
    };
    
    let initial_authority: ContractAddress = 0x123.try_into().unwrap();
    let mut constructor_calldata = array![initial_authority.into()];
    
    let (contract_address, _) = ResultTrait::unwrap(contract.deploy(@constructor_calldata));
    let dispatcher = IRegistryDispatcher { contract_address };

    let user_id = 'user1';
    let data_hash = 'hash123';

    start_cheat_caller_address(contract_address, initial_authority);
    dispatcher.submit_record(user_id, data_hash);
    stop_cheat_caller_address(contract_address);

    let stored_hash = dispatcher.get_record(user_id);
    assert(stored_hash == data_hash, 'Hash mismatch');
}

#[test]
#[should_panic(expected: ('Unauthorized submission', ))]
fn test_unauthorized_submit() {
    let declare_result = ResultTrait::unwrap(declare("Registry"));
    let contract = match declare_result {
        DeclareResult::Success(class) => class,
        DeclareResult::AlreadyDeclared(class) => class,
    };
    
    let initial_authority: ContractAddress = 0x123.try_into().unwrap();
    let mut constructor_calldata = array![initial_authority.into()];
    
    let (contract_address, _) = ResultTrait::unwrap(contract.deploy(@constructor_calldata));
    let dispatcher = IRegistryDispatcher { contract_address };

    let unauthorized_user: ContractAddress = 0x456.try_into().unwrap();
    start_cheat_caller_address(contract_address, unauthorized_user);

    dispatcher.submit_record('user1', 'data');
}
