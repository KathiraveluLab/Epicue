use epicue_core::core::paymaster::{IPaymasterDispatcher, IPaymasterDispatcherTrait};
use starknet::ContractAddress;
use snforge_std::{declare, ContractClassTrait, DeclareResult, start_cheat_caller_address, stop_cheat_caller_address};

fn deploy_paymaster() -> IPaymasterDispatcher {
    let declare_result = declare("Paymaster").unwrap();
    let contract = match declare_result {
        DeclareResult::Success(class) => class,
        DeclareResult::AlreadyDeclared(class) => class,
    };
    let constructor_calldata = array![];
    let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();
    IPaymasterDispatcher { contract_address }
}

#[test]
fn test_sponsored_transaction_flow() {
    let paymaster = deploy_paymaster();
    let sponsor: ContractAddress = 0xabc.try_into().unwrap();
    let user: ContractAddress = 0xdef.try_into().unwrap();
    let target: ContractAddress = 0x777.try_into().unwrap();

    // 1. Sponsor funds the paymaster
    let initial_funding: u256 = 1000;
    paymaster.fund_paymaster(sponsor, initial_funding);
    assert(paymaster.get_sponsor_balance(sponsor) == initial_funding, 'Incorrect initial balance');

    // 2. Sponsor registers the user as sponsored
    start_cheat_caller_address(paymaster.contract_address, sponsor);
    paymaster.register_sponsored_user(sponsor, user);
    stop_cheat_caller_address(paymaster.contract_address);
    assert(paymaster.is_sponsored(sponsor, user), 'User should be sponsored');

    // 3. User initiates a transaction (simulated)
    // Sequencer checks paymaster validation
    let calldata = array![];
    let is_valid = paymaster.validate_paymaster_transaction(user, target, 'submit_record', calldata.span());
    assert(is_valid, 'Transaction should be valid');

    // 4. Sequencer charges gas fee from paymaster sponsor balance
    let gas_fee: u256 = 150;
    paymaster.charge_gas_fee(sponsor, gas_fee);

    // 5. Assert sponsor balance is updated
    let expected_remaining = initial_funding - gas_fee;
    assert(paymaster.get_sponsor_balance(sponsor) == expected_remaining, 'Incorrect remaining balance');
}

#[test]
#[should_panic(expected: ('Insufficient sponsor balance', ))]
fn test_insufficient_sponsor_balance() {
    let paymaster = deploy_paymaster();
    let sponsor: ContractAddress = 0xabc.try_into().unwrap();

    paymaster.fund_paymaster(sponsor, 50);
    paymaster.charge_gas_fee(sponsor, 100);
}
