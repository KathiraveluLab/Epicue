// Epicue contract ABI and environment-aware configuration

export const CONTRACT_ADDRESS =
  process.env.NEXT_PUBLIC_REGISTRY_ADDRESS || 
  "0x035fb9fe792ee212c72632b89e6ac24d5c6a2f0338ffd68d2311bb99359d7ff5";

export const CONTRACT_ABI = [
  {
    type: "impl",
    name: "RegistryImpl",
    interface_name: "epicue_core::registry::IRegistry",
  },
  {
    type: "struct",
    name: "epicue_core::core::types::HealthRecord",
    members: [
      { name: "patient_id", type: "core::felt252" },
      { name: "service_category", type: "core::felt252" },
      { name: "severity", type: "core::integer::u8" },
      { name: "timestamp", type: "core::integer::u64" },
      { name: "data_hash", type: "core::felt252" },
    ],
  },
  {
    type: "struct",
    name: "epicue_core::core::types::EpicueRecord",
    members: [
      { name: "subject_id", type: "core::felt252" },
      { name: "domain", type: "core::felt252" },
      { name: "category", type: "core::felt252" },
      { name: "severity", type: "core::integer::u8" },
      { name: "timestamp", type: "core::integer::u64" },
      { name: "data_hash", type: "core::felt252" },
    ],
  },
  {
    type: "struct",
    name: "epicue_core::triad::governance_voting::Proposal",
    members: [
      { name: "id", type: "core::integer::u64" },
      { name: "proposer", type: "core::starknet::contract_address::ContractAddress" },
      { name: "target", type: "core::starknet::contract_address::ContractAddress" },
      { name: "action_type", type: "core::felt252" },
      { name: "votes_for", type: "core::integer::u64" },
      { name: "votes_against", type: "core::integer::u64" },
      { name: "status", type: "core::felt252" },
      { name: "end_block", type: "core::integer::u64" },
    ],
  },
  {
    type: "interface",
    name: "epicue_core::registry::IRegistry",
    items: [
      {
        type: "function",
        name: "submit_health_record",
        inputs: [{ name: "record", type: "epicue_core::core::types::HealthRecord" }],
        outputs: [],
        state_mutability: "external",
      },
      {
        type: "function",
        name: "get_health_record",
        inputs: [{ name: "patient_id", type: "core::felt252" }],
        outputs: [{ type: "epicue_core::core::types::HealthRecord" }],
        state_mutability: "view",
      },
      {
        type: "function",
        name: "submit_epicue_record",
        inputs: [{ name: "record", type: "epicue_core::core::types::EpicueRecord" }],
        outputs: [],
        state_mutability: "external",
      },
      {
        type: "function",
        name: "get_epicue_record",
        inputs: [{ name: "subject_id", type: "core::felt252" }],
        outputs: [{ type: "epicue_core::core::types::EpicueRecord" }],
        state_mutability: "view",
      },
      {
        type: "function",
        name: "get_record_count",
        inputs: [],
        outputs: [{ type: "core::integer::u64" }],
        state_mutability: "view",
      },
      {
        type: "function",
        name: "get_domain_count",
        inputs: [{ name: "domain", type: "core::felt252" }],
        outputs: [{ type: "core::integer::u64" }],
        state_mutability: "view",
      },
      {
        type: "function",
        name: "propose_action",
        inputs: [
          { name: "target", type: "core::starknet::contract_address::ContractAddress" },
          { name: "action_type", type: "core::felt252" },
        ],
        outputs: [{ type: "core::integer::u64" }],
        state_mutability: "external",
      },
      {
        type: "function",
        name: "vote_on_proposal",
        inputs: [
          { name: "proposal_id", type: "core::integer::u64" },
          { name: "support", type: "core::bool" },
        ],
        outputs: [],
        state_mutability: "external",
      },
      {
        type: "function",
        name: "execute_proposal",
        inputs: [{ name: "proposal_id", type: "core::integer::u64" }],
        outputs: [],
        state_mutability: "external",
      },
      {
        type: "function",
        name: "get_proposal",
        inputs: [{ name: "proposal_id", type: "core::integer::u64" }],
        outputs: [{ type: "epicue_core::triad::governance_voting::Proposal" }],
        state_mutability: "view",
      },
      {
        type: "function",
        name: "get_proposal_count",
        inputs: [],
        outputs: [{ type: "core::integer::u64" }],
        state_mutability: "view",
      },
      {
        type: "function",
        name: "claim_security_bounty",
        inputs: [{ name: "byzantine_node", type: "core::starknet::contract_address::ContractAddress" }],
        outputs: [],
        state_mutability: "external",
      },
      {
        type: "function",
        name: "get_compliance_score",
        inputs: [],
        outputs: [{ type: "core::integer::u8" }],
        state_mutability: "view",
      },
      {
        type: "function",
        name: "get_compliance_label",
        inputs: [],
        outputs: [{ type: "core::felt252" }],
        state_mutability: "view",
      },
      {
        type: "function",
        name: "endorse_methodology",
        inputs: [{ name: "id", type: "core::integer::u64" }],
        outputs: [],
        state_mutability: "external",
      },
    ],
  },
] as const;
