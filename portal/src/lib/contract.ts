// Epicue contract ABI and network constants
// Update CONTRACT_ADDRESS after deploying to Starknet Sepolia

export const CONTRACT_ADDRESS =
  "0x0000000000000000000000000000000000000000000000000000000000000000"; // TODO: replace after deployment

export const CONTRACT_ABI = [
  {
    type: "function",
    name: "submit_health_record",
    inputs: [
      {
        name: "record",
        type: "epicue_core::registry::HealthRecord",
      },
    ],
    outputs: [],
    state_mutability: "external",
  },
  {
    type: "function",
    name: "get_health_record",
    inputs: [{ name: "patient_id", type: "core::felt252" }],
    outputs: [{ type: "epicue_core::registry::HealthRecord" }],
    state_mutability: "view",
  },
  {
    type: "function",
    name: "submit_epicue_record",
    inputs: [
      {
        name: "record",
        type: "epicue_core::registry::EpicueRecord",
      },
    ],
    outputs: [],
    state_mutability: "external",
  },
  {
    type: "function",
    name: "get_epicue_record",
    inputs: [{ name: "subject_id", type: "core::felt252" }],
    outputs: [{ type: "epicue_core::registry::EpicueRecord" }],
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
    name: "get_domain_metadata",
    inputs: [{ name: "domain", type: "core::felt252" }],
    outputs: [
      { type: "core::felt252" },
      { type: "core::felt252" },
    ],
    state_mutability: "view",
  },
  {
    type: "function",
    name: "get_pillar_metadata",
    inputs: [{ name: "pillar", type: "core::felt252" }],
    outputs: [{ type: "core::felt252" }],
    state_mutability: "view",
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
    name: "get_proposal_count",
    inputs: [],
    outputs: [{ type: "core::integer::u64" }],
    state_mutability: "view",
  },
  {
    type: "function",
    name: "add_authority",
    inputs: [
      {
        name: "new_authority",
        type: "core::starknet::contract_address::ContractAddress",
      },
    ],
    outputs: [],
    state_mutability: "external",
  },
  {
    type: "function",
    name: "is_authority",
    inputs: [
      {
        name: "address",
        type: "core::starknet::contract_address::ContractAddress",
      },
    ],
    outputs: [{ type: "core::bool" }],
    state_mutability: "view",
  },
  {
    "type": "function",
    "name": "get_domain_impact",
    "inputs": [
      {
        "name": "domain",
        "type": "core::felt252"
      }
    ],
    "outputs": [{ "type": "core::integer::u64" }],
    "state_mutability": "view"
  },
  {
    "type": "function",
    "name": "get_collaboration_index",
    "inputs": [],
    "outputs": [{ "type": "core::integer::u16" }],
    "state_mutability": "view"
  },
  {
    "type": "function",
    "name": "get_total_verified_records",
    "inputs": [],
    "outputs": [{ "type": "core::integer::u64" }],
    "state_mutability": "view"
  },
  {
    "type": "function",
    "name": "get_geological_record",
    "inputs": [
      {
        "name": "subject_id",
        "type": "core::felt252"
      }
    ],
    "outputs": [
      {
        "type": "epicue_core::types::GeologicalRecord"
      }
    ],
    "state_mutability": "view"
  },
  {
    "type": "function",
    "name": "get_institution_reputation",
    "inputs": [
      {
        "name": "address",
        "type": "core::starknet::contract_address::ContractAddress"
      }
    ],
    "outputs": [
      {
        "type": "epicue_core::reputation::InstitutionReputation"
      }
    ],
    "state_mutability": "view"
  },
  {
    "type": "function",
    "name": "get_system_sustainability_score",
    "inputs": [],
    "outputs": [{ "type": "core::integer::u64" }],
    "state_mutability": "view"
  },
  {
    "type": "function",
    "name": "challenge_record",
    "inputs": [
      {
        "name": "subject_id",
        "type": "core::felt252"
      },
      {
        "name": "scientific_consensus",
        "type": "core::integer::u8"
      }
    ],
    "outputs": [],
    "state_mutability": "external"
  },
  {
    "type": "function",
    "name": "get_review_consensus",
    "inputs": [
      {
        "name": "subject_id",
        "type": "core::felt252"
      }
    ],
    "outputs": [{ "type": "core::integer::u8" }],
    "state_mutability": "view"
  },
] as const;
