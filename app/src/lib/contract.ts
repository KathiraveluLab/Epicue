// Epicue contract ABI and network constants
// Update CONTRACT_ADDRESS after deploying to Starknet Sepolia

export const CONTRACT_ADDRESS =
  "0x0000000000000000000000000000000000000000000000000000000000000000"; // TODO: replace after deployment

export const ABI = [
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
    name: "submit_record",
    inputs: [
      { name: "user_id", type: "core::felt252" },
      { name: "data_hash", type: "core::felt252" },
    ],
    outputs: [],
    state_mutability: "external",
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
    type: "struct",
    name: "epicue_core::registry::HealthRecord",
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
    name: "epicue_core::registry::EpicueRecord",
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
    type: "event",
    name: "epicue_core::registry::Registry::HealthRecordSubmitted",
    kind: "struct",
    members: [
      { name: "patient_id", type: "core::felt252", kind: "key" },
      { name: "service_category", type: "core::felt252", kind: "data" },
      { name: "severity", type: "core::integer::u8", kind: "data" },
      { name: "timestamp", type: "core::integer::u64", kind: "data" },
      { name: "data_hash", type: "core::felt252", kind: "data" },
    ],
  },
  {
    type: "event",
    name: "epicue_core::registry::Registry::EpicueRecordSubmitted",
    kind: "struct",
    members: [
      { name: "subject_id", type: "core::felt252", kind: "key" },
      { name: "domain", type: "core::felt252", kind: "data" },
      { name: "category", type: "core::felt252", kind: "data" },
      { name: "severity", type: "core::integer::u8", kind: "data" },
      { name: "timestamp", type: "core::integer::u64", kind: "data" },
      { name: "data_hash", type: "core::felt252", kind: "data" },
    ],
  },
] as const;
