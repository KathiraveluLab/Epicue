use epicue_core::registry::{IRegistryDispatcher, IRegistryDispatcherTrait};
use epicue_core::triad::governor::{proposal_status};
use epicue_core::triad::governor::actions;
use epicue_core::core::types::{domains, GeologicalRecord, WaterRecord, IndustrialRecord, EducationRecord};
use starknet::ContractAddress;
use snforge_std::{declare, ContractClassTrait, DeclareResult, start_cheat_caller_address, stop_cheat_caller_address};

fn deploy_registry(initial_authority: ContractAddress) -> IRegistryDispatcher {
    let declare_result = declare("Registry").unwrap();
    let contract = match declare_result {
        DeclareResult::Success(class) => class,
        DeclareResult::AlreadyDeclared(class) => class,
    };
    let mut constructor_calldata = array![initial_authority.into()];
    let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();
    IRegistryDispatcher { contract_address }
}

fn onboard_new_authority(
    dispatcher: IRegistryDispatcher,
    proposer: ContractAddress,
    new_auth: ContractAddress,
    existing_authorities: Array<ContractAddress>
) {
    // Proposer proposes new authority
    start_cheat_caller_address(dispatcher.contract_address, proposer);
    let prop_id = dispatcher.propose_action(new_auth, actions::ADD_AUTHORITY);
    stop_cheat_caller_address(dispatcher.contract_address);

    let proposal = dispatcher.get_proposal(prop_id);
    
    // If pending, others need to vote
    if proposal.status == proposal_status::PENDING {
        let mut index = 0_usize;
        loop {
            if index >= existing_authorities.len() {
                break;
            }
            let current_prop = dispatcher.get_proposal(prop_id);
            if current_prop.status != proposal_status::PENDING {
                break;
            }
            let voter = *existing_authorities.at(index);
            // Skip the proposer as they auto-voted during propose_action
            if voter != proposer {
                start_cheat_caller_address(dispatcher.contract_address, voter);
                dispatcher.vote_on_proposal(prop_id, true);
                stop_cheat_caller_address(dispatcher.contract_address);
            }
            index += 1;
        };
    }

    // Execute proposal to finalize onboarding
    start_cheat_caller_address(dispatcher.contract_address, proposer);
    dispatcher.execute_proposal(prop_id);
    stop_cheat_caller_address(dispatcher.contract_address);
}

#[test]
fn test_authority_scaling_sweep() {
    let auth1: ContractAddress = 0x101.try_into().unwrap();
    let auth2: ContractAddress = 0x102.try_into().unwrap();
    let auth3: ContractAddress = 0x103.try_into().unwrap();
    let auth4: ContractAddress = 0x104.try_into().unwrap();
    let auth5: ContractAddress = 0x105.try_into().unwrap();
    let auth6: ContractAddress = 0x106.try_into().unwrap();

    let dispatcher = deploy_registry(auth1);
    assert(dispatcher.get_authority_count() == 1, 'Initial count must be 1');

    // Onboard Auth2 (n=1 -> n=2)
    let mut list = array![auth1];
    onboard_new_authority(dispatcher, auth1, auth2, list.clone());
    assert(dispatcher.is_authority(auth2), 'Auth2 failed onboarding');
    assert(dispatcher.get_authority_count() == 2, 'Count must be 2');

    // Onboard Auth3 (n=2 -> n=3)
    list.append(auth2);
    onboard_new_authority(dispatcher, auth1, auth3, list.clone());
    assert(dispatcher.is_authority(auth3), 'Auth3 failed onboarding');
    assert(dispatcher.get_authority_count() == 3, 'Count must be 3');

    // Onboard Auth4 (n=3 -> n=4)
    list.append(auth3);
    onboard_new_authority(dispatcher, auth1, auth4, list.clone());
    assert(dispatcher.is_authority(auth4), 'Auth4 failed onboarding');
    assert(dispatcher.get_authority_count() == 4, 'Count must be 4');

    // Onboard Auth5 (n=4 -> n=5)
    list.append(auth4);
    onboard_new_authority(dispatcher, auth1, auth5, list.clone());
    assert(dispatcher.is_authority(auth5), 'Auth5 failed onboarding');
    assert(dispatcher.get_authority_count() == 5, 'Count must be 5');

    // Onboard Auth6 (n=5 -> n=6)
    list.append(auth5);
    onboard_new_authority(dispatcher, auth1, auth6, list.clone());
    assert(dispatcher.is_authority(auth6), 'Auth6 failed onboarding');
    assert(dispatcher.get_authority_count() == 6, 'Count must be 6');
}

#[test]
fn test_submit_geology_gas() {
    let auth1: ContractAddress = 0x101.try_into().unwrap();
    let dispatcher = deploy_registry(auth1);

    let geo_record = GeologicalRecord {
        subject_id: 0x201,
        latitude: 4100,
        longitude: -7400,
        sample_depth: 600,
        mineral_density: 700,
        timestamp: 1000
    };

    start_cheat_caller_address(dispatcher.contract_address, auth1);
    dispatcher.submit_geological_record(geo_record);
    stop_cheat_caller_address(dispatcher.contract_address);

    let saved_geo = dispatcher.get_geological_record(0x201);
    assert(saved_geo.latitude == 4100, 'Geological record mismatch');
}

#[test]
fn test_submit_water_gas() {
    let auth1: ContractAddress = 0x101.try_into().unwrap();
    let dispatcher = deploy_registry(auth1);

    let water_record = WaterRecord {
        subject_id: 0x202,
        potability_ppm: 250,
        ph_level: 740,
        leak_detected: false,
        timestamp: 1010
    };
    start_cheat_caller_address(dispatcher.contract_address, auth1);
    dispatcher.submit_water_record(water_record);
    stop_cheat_caller_address(dispatcher.contract_address);

    let saved_water = dispatcher.get_water_record(0x202);
    assert(saved_water.ph_level == 740, 'Water record mismatch');
}

#[test]
fn test_submit_industry_gas() {
    let auth1: ContractAddress = 0x101.try_into().unwrap();
    let dispatcher = deploy_registry(auth1);

    let ind_record = IndustrialRecord {
        subject_id: 0x203,
        carbon_emissions_tons: 350,
        steel_mill_id: 'mill-alpha',
        audit_passed: true,
        timestamp: 1020
    };
    start_cheat_caller_address(dispatcher.contract_address, auth1);
    dispatcher.submit_industrial_record(ind_record);
    stop_cheat_caller_address(dispatcher.contract_address);

    let saved_ind = dispatcher.get_industrial_record(0x203);
    assert(saved_ind.carbon_emissions_tons == 350, 'Industrial record mismatch');
}

#[test]
fn test_submit_education_gas() {
    let auth1: ContractAddress = 0x101.try_into().unwrap();
    let dispatcher = deploy_registry(auth1);

    let edu_record = EducationRecord {
        subject_id: 0x204,
        integrity_index: 92,
        inclusion_score: 88,
        academic_year: 2026,
        timestamp: 1030
    };
    start_cheat_caller_address(dispatcher.contract_address, auth1);
    dispatcher.submit_education_record(edu_record);
    stop_cheat_caller_address(dispatcher.contract_address);

    let saved_edu = dispatcher.get_education_record(0x204);
    assert(saved_edu.integrity_index == 92, 'Education record mismatch');
}

#[test]
fn test_onboard_step_2() {
    let auth1: ContractAddress = 0x101.try_into().unwrap();
    let auth2: ContractAddress = 0x102.try_into().unwrap();
    let dispatcher = deploy_registry(auth1);
    let mut list = array![auth1];
    onboard_new_authority(dispatcher, auth1, auth2, list.clone());
}

#[test]
fn test_onboard_step_3() {
    let auth1: ContractAddress = 0x101.try_into().unwrap();
    let auth2: ContractAddress = 0x102.try_into().unwrap();
    let auth3: ContractAddress = 0x103.try_into().unwrap();
    let dispatcher = deploy_registry(auth1);
    let mut list = array![auth1];
    onboard_new_authority(dispatcher, auth1, auth2, list.clone());
    list.append(auth2);
    onboard_new_authority(dispatcher, auth1, auth3, list.clone());
}

#[test]
fn test_onboard_step_4() {
    let auth1: ContractAddress = 0x101.try_into().unwrap();
    let auth2: ContractAddress = 0x102.try_into().unwrap();
    let auth3: ContractAddress = 0x103.try_into().unwrap();
    let auth4: ContractAddress = 0x104.try_into().unwrap();
    let dispatcher = deploy_registry(auth1);
    let mut list = array![auth1];
    onboard_new_authority(dispatcher, auth1, auth2, list.clone());
    list.append(auth2);
    onboard_new_authority(dispatcher, auth1, auth3, list.clone());
    list.append(auth3);
    onboard_new_authority(dispatcher, auth1, auth4, list.clone());
}

#[test]
fn test_onboard_step_5() {
    let auth1: ContractAddress = 0x101.try_into().unwrap();
    let auth2: ContractAddress = 0x102.try_into().unwrap();
    let auth3: ContractAddress = 0x103.try_into().unwrap();
    let auth4: ContractAddress = 0x104.try_into().unwrap();
    let auth5: ContractAddress = 0x105.try_into().unwrap();
    let dispatcher = deploy_registry(auth1);
    let mut list = array![auth1];
    onboard_new_authority(dispatcher, auth1, auth2, list.clone());
    list.append(auth2);
    onboard_new_authority(dispatcher, auth1, auth3, list.clone());
    list.append(auth3);
    onboard_new_authority(dispatcher, auth1, auth4, list.clone());
    list.append(auth4);
    onboard_new_authority(dispatcher, auth1, auth5, list.clone());
}

