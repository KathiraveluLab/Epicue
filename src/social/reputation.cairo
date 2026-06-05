use starknet::ContractAddress;

#[derive(Copy, Drop, Serde, PartialEq, starknet::Store, Default)]
pub enum NodeStatus {
    #[default]
    Compliant,
    Failing,
    Byzantine,
}

#[derive(Drop, Serde, starknet::Store)]
pub struct InstitutionReputation {
    pub institution: ContractAddress,
    pub reputation_credits: u64, // Result of Inner Integral: ∫ τ(p, t) dp
    pub last_activity_timestamp: u64,
    pub trust_multiplier: u8, // Scaling factor for long-term integrity
    pub bounty_credits: u64, // Security contributions
    pub spatiotemporal_trust: u128, // Double Integral: ∫ ∫ τ(p, t) dp dt
    pub status: NodeStatus, // Flagged via Trust Gradient Divergence (∇S)
    pub consecutive_active_duration: u64, // Tracks consecutive active participation time
}

/// Dynamic Trust Level (T(t) = ∫ τ(p, t) dp)
/// Aggregates trust across the entire policy domain space (P).
pub fn calculate_dynamic_trust_level(rep: @InstitutionReputation, green_stature: u64) -> u64 {
    let multiplier = if *rep.trust_multiplier == 0 { 1 } else { *rep.trust_multiplier };
    let base_trust = (*rep.reputation_credits) + green_stature + (*rep.bounty_credits);
    base_trust * multiplier.into()
}

/// Update Institutional Trust as a Spatiotemporal Double Integral
/// S = ∫ ∫ τ(p, t) dp dt ≈ Σ T_i * Δt_i
pub fn update_spatiotemporal_trust(ref rep: InstitutionReputation, green_stature: u64, current_timestamp: u64) {
    if rep.trust_multiplier == 0 {
        rep.trust_multiplier = 1;
    }
    if rep.last_activity_timestamp == 0 {
        rep.last_activity_timestamp = current_timestamp;
        return;
    }
    
    if current_timestamp <= rep.last_activity_timestamp { return; }
    
    let elapsed = current_timestamp - rep.last_activity_timestamp;
    
    // T(t) represents the aggregate trust density over the policy domain at time t
    let trust_density = calculate_dynamic_trust_level(@rep, green_stature);
    
    rep.spatiotemporal_trust += trust_density.into() * elapsed.into();
}

pub fn calculate_credit_gain(severity: u8, domain: felt252) -> u64 {
    // Basic incentive logic: higher severity data earns more reputation credits
    // This rewards "high-value" contributions to the registry
    (severity.into() * 10)
}

/// Incentivizes "Net Zero" achievements by awarding significant credit gains
pub fn calculate_sustainability_bonus(green_stature: u64) -> u64 {
    green_stature / 50
}

/// Awards bounty credits to auditors who successfully flag byzantine behavior
pub fn calculate_bounty_reward(severity: u8, impact: u64) -> u64 {
    (severity.into() * 50) + (impact / 100)
}

/// Penalizes a node for byzantine behavior by reducing reputation based on severity
pub fn apply_graded_slashing(ref reputation: InstitutionReputation, severity: u8) {
    if severity == 3 { // CRITICAL
        reputation.reputation_credits = 0;
        reputation.trust_multiplier = 1;
        reputation.status = NodeStatus::Byzantine; // Complete Divergence
    } else if severity == 2 { // MAJOR
        reputation.reputation_credits = (reputation.reputation_credits * 50) / 100;
        reputation.trust_multiplier = 1;
        reputation.status = NodeStatus::Byzantine; // Divergence detected
    } else if severity == 1 { // MINOR
        reputation.reputation_credits = (reputation.reputation_credits * 75) / 100;
        if reputation.trust_multiplier > 1 {
            reputation.trust_multiplier -= 1;
        }
    }
}

/// Detects if a node is transitioning into a Byzantine or Failing state through trust erosion.
/// Corresponds to the refined Trust Gradient Status model in Eq. 10.
pub fn detect_trust_divergence(old_density: u64, new_density: u64, threshold: u64) -> NodeStatus {
    if old_density > new_density {
        let gradient = old_density - new_density;
        if gradient > threshold {
            return NodeStatus::Byzantine;
        } else {
            return NodeStatus::Failing;
        }
    }
    NodeStatus::Compliant
}

pub mod reputation_tiers {
    pub const BRONZE: u64 = 100;
    pub const SILVER: u64 = 500;
    pub const GOLD: u64 = 1000;
}

pub const DECAY_PERIOD: u64 = 2592000; // 30 days
pub const TRUST_RESET_PERIOD: u64 = 7776000; // 90 days

/// Calculates and applies reputation decay based on inactivity, respecting a minimum floor
/// Also implements dynamic trust multiplier recovery for active participation.
pub fn apply_reputation_decay(ref reputation: InstitutionReputation, current_timestamp: u64, min_floor: u64) {
    if reputation.trust_multiplier == 0 {
        reputation.trust_multiplier = 1;
    }
    if reputation.last_activity_timestamp == 0 { return; }
    if current_timestamp <= reputation.last_activity_timestamp { return; }

    let elapsed = current_timestamp - reputation.last_activity_timestamp;
    
    // Multiplier reset for extreme inactivity
    if elapsed > TRUST_RESET_PERIOD {
        reputation.trust_multiplier = 1;
        reputation.consecutive_active_duration = 0;
    } else {
        // Accumulate active duration if no decay/inactivity has broken the streak
        if elapsed < DECAY_PERIOD {
            reputation.consecutive_active_duration += elapsed;
            let growth_periods = reputation.consecutive_active_duration / DECAY_PERIOD;
            if growth_periods > 0 {
                let max_multiplier: u8 = 5;
                if reputation.trust_multiplier < max_multiplier {
                    let new_mult = reputation.trust_multiplier + growth_periods.try_into().unwrap_or(0);
                    if new_mult > max_multiplier {
                        reputation.trust_multiplier = max_multiplier;
                    } else {
                        reputation.trust_multiplier = new_mult;
                    }
                }
                reputation.consecutive_active_duration %= DECAY_PERIOD;
            }
        }
    }

    // Credits decay: 5% per 30 days
    let periods = elapsed / DECAY_PERIOD;
    if periods > 0 {
        // Streak is broken by decay period inactivity
        reputation.consecutive_active_duration = 0;
        
        if reputation.reputation_credits > min_floor {
            let decay_amount = (reputation.reputation_credits * 5 * periods) / 100;
            
            if decay_amount >= reputation.reputation_credits {
                reputation.reputation_credits = min_floor;
            } else {
                let potential_new_credits = reputation.reputation_credits - decay_amount;
                if potential_new_credits < min_floor {
                    reputation.reputation_credits = min_floor;
                } else {
                    reputation.reputation_credits = potential_new_credits;
                }
            }
        }
    }
}
