"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import { useAccount, useContract, useSendTransaction, useReadContract } from "@starknet-react/core";
import { CONTRACT_ADDRESS, CONTRACT_ABI } from "@/lib/contract";
import { num, uint256 } from "starknet";

// Status helpers
const getStatusColor = (status: string) => {
  switch (status) {
    case "PENDING": return "text-yellow-400 bg-yellow-400/10";
    case "APPROVED": return "text-emerald-400 bg-emerald-400/10";
    case "REJECTED": return "text-rose-400 bg-rose-400/10";
    case "EXECUTED": return "text-blue-400 bg-blue-400/10";
    default: return "text-white/40 bg-white/5";
  }
};

export default function GovernancePage() {
  const { address } = useAccount();
  const [proposalCount, setProposalCount] = useState<number>(0);
  const [proposals, setProposals] = useState<any[]>([]);

  // Contract reads
  const { data: countData } = useReadContract({
    functionName: "get_proposal_count",
    address: CONTRACT_ADDRESS,
    abi: CONTRACT_ABI,
    args: [],
    watch: true,
  });

  useEffect(() => {
    if (countData) {
      setProposalCount(Number(countData));
    }
  }, [countData]);

  return (
    <main className="min-h-screen bg-[#050505] text-white p-8">
      <div className="max-w-6xl mx-auto">
        <header className="mb-12">
          <Link href="/" className="text-white/40 hover:text-white transition-colors mb-4 inline-block text-sm">
            ← Back to Registry
          </Link>
          <h1 className="text-5xl font-bold tracking-tighter mb-4">Decentralized Governance</h1>
          <p className="text-xl text-white/40 max-w-2xl font-light leading-relaxed">
            The EQUISYS Participatory Design engine. Existing authorities can propose systemic changes and vote on authority delegation via STARK-verified consensus.
          </p>
        </header>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Active Proposals */}
          <section className="lg:col-span-2 space-y-6">
            <h2 className="text-xl font-semibold mb-6 flex items-center gap-3">
              Active Proposals
              <span className="px-2 py-0.5 rounded-full bg-white/5 text-xs font-mono text-white/40">{proposalCount}</span>
            </h2>

            {proposalCount === 0 ? (
              <div className="rounded-2xl border border-white/5 bg-white/[0.02] p-12 text-center">
                <p className="text-white/20">No active proposals found in the EQUISYS state.</p>
              </div>
            ) : (
              <div className="space-y-4">
                {/* Proposal cards would be mapped here */}
                {[...Array(proposalCount)].map((_, i) => (
                  <ProposalCard key={i} id={i + 1} />
                ))}
              </div>
            )}
          </section>

          {/* New Proposal Sideboard */}
          <aside className="space-y-6">
            <div className="rounded-3xl border border-white/5 bg-white/[0.02] p-8">
              <h2 className="text-xl font-semibold mb-6">New Action</h2>
              <form className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-white/40 mb-2">Target Address</label>
                  <input 
                    type="text" 
                    placeholder="0x..."
                    className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-sm focus:outline-none focus:ring-1 focus:ring-white/20 transition-all"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-white/40 mb-2">Action Type</label>
                  <select className="w-full bg-[#0a0a0a] border border-white/10 rounded-xl px-4 py-3 text-sm focus:outline-none focus:ring-1 focus:ring-white/20 transition-all appearance-none cursor-pointer">
                    <option value="ADD_AUTH">Add New Authority</option>
                    <option value="REMOVE_AUTH">Remove Authority</option>
                  </select>
                </div>
                <button 
                  disabled
                  className="w-full bg-white text-black font-bold py-4 rounded-2xl hover:bg-white/90 disabled:opacity-50 disabled:cursor-not-allowed transition-all mt-6"
                >
                  Create Proposal
                </button>
              </form>
            </div>

            <div className="rounded-3xl border border-white/5 bg-white/[0.02] p-8">
              <h3 className="text-xs font-bold uppercase tracking-widest text-white/20 mb-4">Governance Rules</h3>
              <ul className="space-y-3 text-sm text-white/40">
                <li className="flex gap-2"><span>•</span> Quorum: 51% of active authorities.</li>
                <li className="flex gap-2"><span>•</span> Status: STARK-verified consensus.</li>
                <li className="flex gap-2"><span>•</span> Finality: Execution requires proof of approved status.</li>
              </ul>
            </div>
          </aside>
        </div>
      </div>
    </main>
  );
}

function ProposalCard({ id }: { id: number }) {
  // Normally we would read the proposal data from the contract
  return (
    <div className="rounded-3xl border border-white/5 bg-white/[0.02] p-8 hover:bg-white/[0.03] transition-all group">
      <div className="flex justify-between items-start mb-6">
        <div>
          <span className="text-xs font-mono text-white/20 mb-1 block">proposal_id: {id}</span>
          <h3 className="text-xl font-bold">Add Authority: 0x4f...2a</h3>
        </div>
        <span className={`px-3 py-1 rounded-full text-[10px] font-bold tracking-wider uppercase bg-yellow-400/10 text-yellow-400`}>
          PENDING
        </span>
      </div>

      <div className="flex gap-8 mb-8">
        <div>
          <div className="text-xs text-white/20 uppercase font-bold tracking-widest mb-1">For</div>
          <div className="text-2xl font-mono">1</div>
        </div>
        <div>
          <div className="text-xs text-white/20 uppercase font-bold tracking-widest mb-1">Against</div>
          <div className="text-2xl font-mono">0</div>
        </div>
        <div className="flex-grow flex items-end">
            <div className="w-full h-1 bg-white/5 rounded-full overflow-hidden">
                <div className="h-full bg-emerald-400" style={{ width: "100%" }} />
            </div>
        </div>
      </div>

      <div className="flex gap-3">
        <button disabled className="flex-1 bg-white/5 border border-white/10 text-white font-bold py-3 rounded-xl hover:bg-emerald-500/10 hover:border-emerald-500/50 hover:text-emerald-400 transition-all">
          Vote For
        </button>
        <button disabled className="flex-1 bg-white/5 border border-white/10 text-white font-bold py-3 rounded-xl hover:bg-rose-500/10 hover:border-rose-500/50 hover:text-rose-400 transition-all">
          Vote Against
        </button>
      </div>
    </div>
  );
}
