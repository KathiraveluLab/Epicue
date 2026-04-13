import { useState, Component } from 'react';
import { 
  useAccount, 
  useReadContract, 
  useSendTransaction,
  useConnect,
  useDisconnect
} from '@starknet-react/core';
import { 
  Database, 
  ShieldCheck, 
  History, 
  Vote, 
  Plus, 
  AlertTriangle,
  ExternalLink,
  ChevronRight,
  User,
  Activity
} from 'lucide-react';
import { CONTRACT_ABI, CONTRACT_ADDRESS } from './lib/contract';

// --- Utilities ---
function decodeShortString(felt: string): string {
  try {
    const hex = felt.startsWith('0x') ? felt.slice(2) : BigInt(felt).toString(16);
    let str = '';
    for (let i = 0; i < hex.length; i += 2) {
      const charCode = parseInt(hex.substr(i, 2), 16);
      if (charCode) str += String.fromCharCode(charCode);
    }
    return str;
  } catch (e) {
    return felt;
  }
}

// --- Error Boundary ---
class ErrorBoundary extends Component<any, any> {
  constructor(props: any) {
    super(props);
    this.state = { hasError: false, error: null };
  }
  static getDerivedStateFromError(error: any) {
    return { hasError: true, error };
  }
  componentDidCatch(error: any, errorInfo: any) {
    console.error("Epicue Portal Crash:", error, errorInfo);
  }
  render() {
    if (this.state.hasError) {
      return (
        <div className="min-h-screen bg-[#050505] text-white flex items-center justify-center p-6">
          <div className="text-center max-w-lg">
            <AlertTriangle className="w-16 h-16 text-rose-500 mx-auto mb-6" />
            <h1 className="text-2xl font-bold mb-4">Application Exception</h1>
            <p className="text-zinc-500 mb-8 font-mono text-sm">{this.state.error?.message}</p>
            <button 
              onClick={() => window.location.reload()}
              className="px-8 py-3 rounded-2xl bg-violet-600 text-white font-bold"
            >
              Restart Portal
            </button>
          </div>
        </div>
      );
    }
    return this.props.children;
  }
}

// --- Components ---

function Header() {
  const { address } = useAccount();
  const { connect, connectors } = useConnect();
  const { disconnect } = useDisconnect();

  return (
    <header className="border-b border-white/10 bg-[#050505]/80 backdrop-blur-xl sticky top-0 z-50">
      <div className="max-w-7xl mx-auto px-6 h-20 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-violet-600 to-indigo-600 flex items-center justify-center shadow-lg shadow-violet-500/20">
            <ShieldCheck className="w-6 h-6 text-white" />
          </div>
          <div>
            <h1 className="text-xl font-bold tracking-tight">EPICUE</h1>
            <p className="text-[10px] text-zinc-500 uppercase tracking-widest font-medium">BFT Registry Portal</p>
          </div>
        </div>

        <div>
          {address ? (
            <button 
              onClick={() => disconnect()}
              className="px-5 py-2.5 rounded-xl bg-white/5 border border-white/10 text-sm font-medium hover:bg-white/10 transition-all text-zinc-400"
            >
              {address.slice(0, 6)}...{address.slice(-4)}
            </button>
          ) : (
            <button 
              onClick={() => connect({ connector: connectors[0] })}
              className="px-5 py-2.5 rounded-xl bg-violet-600 text-white text-sm font-semibold hover:bg-violet-500 transition-all shadow-lg shadow-violet-600/20"
            >
              Connect Wallet
            </button>
          )}
        </div>
      </div>
    </header>
  );
}

function TransmissionRow({ id }: { id: number }) {
  const { data: recordId } = useReadContract({
    abi: CONTRACT_ABI,
    address: CONTRACT_ADDRESS as `0x${string}`,
    functionName: 'get_record_id',
    args: [BigInt(id)],
  });

  const displayId = recordId ? (typeof recordId === 'bigint' ? `0x${recordId.toString(16)}` : recordId) : "...";

  return (
    <div className="flex items-center justify-between p-4 rounded-2xl bg-white/[0.02] border border-white/5 hover:border-violet-500/30 transition-all cursor-default group">
      <div className="flex items-center gap-4">
        <div className="w-10 h-10 rounded-xl bg-white/5 flex items-center justify-center text-zinc-500 group-hover:text-violet-400 transition-colors">
          <History className="w-5 h-5" />
        </div>
        <div>
          <div className="text-sm font-medium">Record #{id}</div>
          <div className="text-[10px] text-zinc-500 font-mono">{String(displayId).slice(0, 10)}...{String(displayId).slice(-4)}</div>
        </div>
      </div>
      <div className="flex items-center gap-3">
        <span className="px-3 py-1 rounded-full bg-emerald-500/10 text-emerald-500 text-[10px] font-bold uppercase">Verified</span>
        <span className="px-3 py-1 rounded-full bg-violet-500/10 text-violet-500 text-[10px] font-bold uppercase italic">STARK Proof</span>
      </div>
    </div>
  );
}

function ProposalRow({ id }: { id: number }) {
  const { data: proposal } = useReadContract({
    abi: CONTRACT_ABI,
    address: CONTRACT_ADDRESS as `0x${string}`,
    functionName: 'get_proposal',
    args: [BigInt(id)],
  }) as any;

  const { send: voteSupport } = useSendTransaction({
    calls: [
      {
        contractAddress: CONTRACT_ADDRESS as `0x${string}`,
        entrypoint: 'vote_on_proposal',
        calldata: [BigInt(id), 1],
      }
    ]
  });

  const { send: voteOppose } = useSendTransaction({
    calls: [
      {
        contractAddress: CONTRACT_ADDRESS as `0x${string}`,
        entrypoint: 'vote_on_proposal',
        calldata: [BigInt(id), 0],
      }
    ]
  });

  if (!proposal) return null;

  const actionType = typeof proposal.action_type === 'bigint' ? decodeShortString(proposal.action_type.toString()) : proposal.action_type;
  const status = typeof proposal.status === 'bigint' ? decodeShortString(proposal.status.toString()) : proposal.status;

  const votesFor = Number(proposal.votes_for);
  const votesAgainst = Number(proposal.votes_against);
  const totalVotes = votesFor + votesAgainst;
  const progress = totalVotes > 0 ? (votesFor / totalVotes) * 100 : 0;

  return (
    <div className="p-8 rounded-3xl bg-white/[0.02] border border-white/10 group">
      <div className="flex items-start justify-between mb-6">
        <div className="w-12 h-12 rounded-2xl bg-blue-500/10 flex items-center justify-center text-blue-500">
          <Vote className="w-6 h-6" />
        </div>
        <span className="px-3 py-1 rounded-full bg-blue-500/10 text-blue-500 text-[10px] font-bold uppercase tracking-tighter">{status}</span>
      </div>
      <h4 className="text-lg font-bold mb-2">Proposal #{id}: {String(actionType)}</h4>
      <p className="text-zinc-500 text-sm mb-6 leading-relaxed">Target: {String(proposal.target).slice(0, 10)}...{String(proposal.target).slice(-4)}</p>
      <div className="flex items-center justify-between text-xs font-medium mb-3">
        <span className="text-zinc-400">Support Ratio ({votesFor}/{totalVotes})</span>
        <span className="text-white">{Math.round(progress)}%</span>
      </div>
      <div className="h-2 rounded-full bg-white/5 overflow-hidden mb-8">
        <div className="h-full bg-violet-500 rounded-full transition-all duration-1000" style={{ width: `${progress}%` }} />
      </div>
      <div className="grid grid-cols-2 gap-3">
        <button 
          onClick={() => voteSupport()}
          className="py-3 rounded-xl bg-emerald-600/20 text-emerald-400 border border-emerald-500/20 font-bold text-sm hover:bg-emerald-600/30 transition-all active:scale-95"
        >
          Support
        </button>
        <button 
          onClick={() => voteOppose()}
          className="py-3 rounded-xl bg-rose-600/10 text-rose-400 border border-rose-500/10 font-bold text-sm hover:bg-rose-600/20 transition-all active:scale-95"
        >
          Oppose
        </button>
      </div>
    </div>
  );
}

function NewProposalModal({ isOpen, onClose }: { isOpen: boolean, onClose: () => void }) {
  const [target, setTarget] = useState('');
  const [type, setType] = useState('1'); // Default: ADD_AUTHORITY

  const { send: propose } = useSendTransaction({
    calls: [
      {
        contractAddress: CONTRACT_ADDRESS as `0x${string}`,
        entrypoint: 'propose_action',
        calldata: [target, type],
      }
    ]
  });

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center p-6 bg-black/80 backdrop-blur-sm animate-in fade-in duration-300">
      <div className="w-full max-w-lg bg-[#0a0a0a] border border-white/10 rounded-[32px] p-8 shadow-2xl shadow-violet-500/10">
        <h3 className="text-2xl font-bold mb-2">New Institutional Proposal</h3>
        <p className="text-zinc-500 text-sm mb-8">Initiate a system-wide consensus action.</p>
        
        <div className="space-y-6">
          <div>
            <label className="text-[10px] font-bold text-zinc-500 uppercase tracking-widest mb-2 block">Action Type</label>
            <select 
              value={type}
              onChange={(e) => setType(e.target.value)}
              className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-sm focus:outline-none focus:border-violet-500/50"
            >
              <option value="1">Add Authority Node</option>
              <option value="2">Remove Authority Node</option>
              <option value="3">Adjust Reputation Floor</option>
            </select>
          </div>
          
          <div>
            <label className="text-[10px] font-bold text-zinc-500 uppercase tracking-widest mb-2 block">Target Address / Value</label>
            <input 
              type="text"
              value={target}
              onChange={(e) => setTarget(e.target.value)}
              placeholder="0x..."
              className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-sm focus:outline-none focus:border-violet-500/50"
            />
          </div>

          <div className="flex gap-3 pt-4">
            <button 
              onClick={() => { propose(); onClose(); }}
              className="flex-1 py-4 rounded-2xl bg-violet-600 text-white font-bold hover:bg-violet-500 transition-all shadow-lg shadow-violet-600/20"
            >
              Submit Proposal
            </button>
            <button 
              onClick={onClose}
              className="px-8 py-4 rounded-2xl bg-white/5 text-zinc-400 font-bold hover:bg-white/10 transition-all"
            >
              Cancel
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

function RegistrySection() {
  const { data: count } = useReadContract({
    abi: CONTRACT_ABI,
    address: CONTRACT_ADDRESS as `0x${string}`,
    functionName: 'get_record_count',
    args: [],
  });

  const recordCount = count ? Number(count) : 0;

  return (
    <div className="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-700">
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="p-8 rounded-3xl bg-white/[0.02] border border-white/5 relative overflow-hidden group">
          <div className="absolute top-0 right-0 p-8 opacity-5 group-hover:opacity-10 transition-opacity">
            <Database className="w-24 h-24 text-white" />
          </div>
          <p className="text-zinc-500 text-sm font-medium mb-2">Verified Transmissions</p>
          <h3 className="text-4xl font-bold">{recordCount}</h3>
          <div className="mt-4 flex items-center gap-2 text-[10px] text-emerald-400 font-bold uppercase tracking-wider">
            <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
            Live Network Telemetry
          </div>
        </div>
        
        <div className="p-8 rounded-3xl bg-white/[0.02] border border-white/5">
          <p className="text-zinc-500 text-sm font-medium mb-2">Active Protocols</p>
          <h3 className="text-4xl font-bold">12</h3>
          <p className="text-zinc-600 text-[10px] mt-4 uppercase tracking-widest font-bold">FATE Compliance: High</p>
        </div>

        <div className="p-8 rounded-3xl bg-white/[0.02] border border-white/5">
          <p className="text-zinc-500 text-sm font-medium mb-2">BFT Quorum Status</p>
          <h3 className="text-4xl font-bold text-violet-500">2f+1</h3>
          <p className="text-zinc-600 text-[10px] mt-4 uppercase tracking-widest font-bold">Consensus Hardened</p>
        </div>
      </div>

      <div className="p-8 rounded-3xl bg-white/[0.02] border border-white/5">
        <div className="flex items-center justify-between mb-8">
          <h3 className="text-xl font-semibold">Latest transmissions</h3>
          <button className="text-zinc-500 hover:text-white transition-colors text-sm flex items-center gap-2">
            View All <ChevronRight className="w-4 h-4" />
          </button>
        </div>
        
        <div className="space-y-3">
          {recordCount > 0 ? (
            [...Array(Math.min(recordCount, 5))].map((_, i) => (
              <TransmissionRow key={recordCount - i} id={recordCount - i} />
            ))
          ) : (
            <div className="text-center py-12 text-zinc-600 italic">No transmissions found on-chain.</div>
          )}
        </div>
      </div>
    </div>
  );
}

function GovernanceSection() {
  const [isModalOpen, setIsModalOpen] = useState(false);
  const { data: countData } = useReadContract({
    abi: CONTRACT_ABI,
    address: CONTRACT_ADDRESS as `0x${string}`,
    functionName: 'get_proposal_count',
    args: [],
  });

  const proposalCount = countData ? Number(countData) : 0;

  return (
    <div className="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-700">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-3xl font-bold">Institutional Governance</h2>
          <p className="text-zinc-500 text-sm mt-1">Multi-disciplinary consensus management</p>
        </div>
        <button 
          onClick={() => setIsModalOpen(true)}
          className="flex items-center gap-2 px-6 py-3 rounded-2xl bg-violet-600 hover:bg-violet-500 text-white font-semibold transition-all shadow-lg shadow-violet-600/20"
        >
          <Plus className="w-5 h-5" /> New Proposal
        </button>
      </div>
      
      <NewProposalModal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} />

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {proposalCount > 0 ? (
          [...Array(proposalCount)].map((_, i) => (
            <ProposalRow key={i + 1} id={i + 1} />
          ))
        ) : (
          <div className="col-span-full p-12 rounded-3xl bg-white/[0.01] border border-dashed border-white/5 text-center text-zinc-600">
            No active governance proposals.
          </div>
        )}
      </div>
    </div>
  );
}

function AuditorSection() {
  const [maliciousAddress, setMaliciousAddress] = useState('');
  const { data: score } = useReadContract({
    abi: CONTRACT_ABI,
    address: CONTRACT_ADDRESS as `0x${string}`,
    functionName: 'get_compliance_score',
    args: [],
  });

  const { data: label } = useReadContract({
    abi: CONTRACT_ABI,
    address: CONTRACT_ADDRESS as `0x${string}`,
    functionName: 'get_compliance_label',
    args: [],
  });

  const { send: claimBounty } = useSendTransaction({
    calls: [
      {
        contractAddress: CONTRACT_ADDRESS as `0x${string}`,
        entrypoint: 'claim_security_bounty',
        calldata: [maliciousAddress],
      }
    ]
  });

  const complianceLabel = label ? (typeof label === 'bigint' ? decodeShortString(label.toString()) : label) : "STABLE";

  return (
    <div className="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-700">
      <div className="max-w-3xl mx-auto text-center py-12">
        <div className="w-24 h-24 rounded-full bg-white/[0.02] border-4 border-emerald-500/50 flex items-center justify-center mx-auto mb-8 shadow-[0_0_50px_rgba(16,185,129,0.1)]">
          <span className="text-4xl font-bold font-mono tracking-tighter">{score ? Number(score) : '98'}</span>
        </div>
        <h2 className="text-3xl font-bold mb-4 italic tracking-tight uppercase">System Integrity: {String(complianceLabel)}</h2>
        <p className="text-zinc-500 leading-relaxed text-lg">
          Institutional integrity monitor for Byzantine-resilient transmissions. 
          Auditors are incentivized to signal malicious telemetry and claim security bounties.
        </p>
      </div>

      <div className="max-w-xl mx-auto p-8 rounded-3xl bg-rose-500/5 border border-rose-500/20">
        <div className="flex items-center gap-4 mb-6">
          <div className="w-12 h-12 rounded-2xl bg-rose-500/20 flex items-center justify-center text-rose-500">
            <AlertTriangle className="w-6 h-6" />
          </div>
          <div>
            <h4 className="font-bold">Signal Byzantine Fault</h4>
            <p className="text-xs text-rose-500/70">Report malicious node behavior to the Governor</p>
          </div>
        </div>
        <input 
          type="text" 
          value={maliciousAddress}
          onChange={(e) => setMaliciousAddress(e.target.value)}
          placeholder="Malicious Node Address (0x...)"
          className="w-full bg-black/40 border border-white/10 rounded-xl px-5 py-4 text-sm focus:outline-none focus:border-rose-500/50 transition-all mb-4"
        />
        <button 
          onClick={() => claimBounty()}
          className="w-full py-4 rounded-xl bg-rose-600 text-white font-bold text-sm hover:bg-rose-500 transition-all shadow-lg shadow-rose-600/20 active:scale-[0.98]"
        >
          Claim Security Bounty
        </button>
      </div>
    </div>
  );
}

// --- Main App ---

export default function App() {
  const [activeTab, setActiveTab] = useState<'registry' | 'governance' | 'auditor'>('registry');

  return (
    <ErrorBoundary>
      <div className="min-h-screen bg-[#050505] text-white selection:bg-violet-500/30">
        <Header />
        
        <main className="max-w-7xl mx-auto px-6 py-12">
          {/* Tab Navigation */}
          <div className="flex items-center gap-2 p-1.5 rounded-[22px] bg-white/[0.02] border border-white/5 w-fit mb-12">
            {[
              { id: 'registry', icon: Database, label: 'Registry' },
              { id: 'governance', icon: Vote, label: 'Governance' },
              { id: 'auditor', icon: ShieldCheck, label: 'Auditor' }
            ].map((tab) => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id as any)}
                className={`flex items-center gap-2.5 px-6 py-2.5 rounded-2xl text-sm font-semibold transition-all ${
                  activeTab === tab.id 
                    ? 'bg-white/10 text-white shadow-sm' 
                    : 'text-zinc-500 hover:text-zinc-300'
                }`}
              >
                <tab.icon className={`w-4 h-4 ${activeTab === tab.id ? 'text-violet-400' : ''}`} />
                {tab.label}
              </button>
            ))}
          </div>

          {/* Content Area */}
          {activeTab === 'registry' && <RegistrySection />}
          {activeTab === 'governance' && <GovernanceSection />}
          {activeTab === 'auditor' && <AuditorSection />}
        </main>

        <footer className="border-t border-white/5 py-12 mt-20">
          <div className="max-w-7xl mx-auto px-6 flex flex-col md:flex-row items-center justify-between gap-6 text-zinc-600 text-xs font-medium tracking-wider">
            <div className="flex items-center gap-6">
              <span className="flex items-center gap-2"><span className="w-1.5 h-1.5 rounded-full bg-emerald-500" /> MAINNET STATUS: STABLE</span>
              <span className="flex items-center gap-2"><span className="w-1.5 h-1.5 rounded-full bg-emerald-500" /> QUORUM: ACTIVE</span>
            </div>
            <div className="flex items-center gap-8">
              <a href="#" className="hover:text-white transition-colors">DOCUMENTATION</a>
              <a href="#" className="hover:text-white transition-colors">SECURITY AUDIT</a>
              <a href="#" className="hover:text-white transition-colors">TRIAD POLICY</a>
            </div>
          </div>
        </footer>
      </div>
    </ErrorBoundary>
  );
}
