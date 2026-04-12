"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import { useAccount, useSendTransaction, useReadContract } from "@starknet-react/core";
import { CONTRACT_ADDRESS, CONTRACT_ABI } from "@/lib/contract";
import { num, shortString } from "starknet";
import { WalletButton } from "@/components/WalletButton";
import { ArrowLeft, Plus, CheckCircle2, XCircle, Play } from "lucide-react";

// Status helpers
const getStatusLabel = (status: any) => {
  const s = status ? shortString.decodeShortString(num.toHex(status)) : "UNKNOWN";
  return s;
};

export default function GovernancePage() {
  const { address } = useAccount();
  const [targetAddr, setTargetAddr] = useState("");
  const [actionType, setActionType] = useState("ADD_AUTH");

  const { data: countData } = useReadContract({
    functionName: "get_proposal_count",
    address: CONTRACT_ADDRESS as `0x${string}`,
    abi: CONTRACT_ABI,
    args: [],
    watch: true,
  });

  const proposalCount = countData ? Number(countData) : 0;

  const { send: createProposal, isPending: isProposing } = useSendTransaction({
    calls: [
      {
        contractAddress: CONTRACT_ADDRESS,
        entrypoint: "propose_action",
        calldata: [targetAddr, shortString.encodeShortString(actionType)],
      },
    ],
  });

  return (
    <main className="min-h-screen bg-[#050505] text-white">
      <nav className="flex items-center justify-between px-8 py-5 border-b border-white/5 bg-[#050505]/80 backdrop-blur-xl sticky top-0 z-50">
        <div className="flex items-center gap-6">
          <Link href="/" className="flex items-center gap-3 group">
            <div className="w-8 h-8 rounded-lg bg-white/5 border border-white/10 flex items-center justify-center group-hover:bg-white/10 transition-all">
              <ArrowLeft className="w-4 h-4 text-white" />
            </div>
          </Link>
          <div className="h-6 w-px bg-white/10" />
          <span className="font-bold text-white tracking-tight">Decentralized Governance</span>
        </div>
        <WalletButton />
      </nav>

      <div className="max-w-6xl mx-auto p-8 py-16">
        <header className="mb-12">
          <h1 className="text-5xl font-bold tracking-tighter mb-4">Participatory Design</h1>
          <p className="text-xl text-white/30 max-w-2xl font-light leading-relaxed">
            Authorities can propose expansions, update reputation floors, and vote on system evolution via BFT-verified consensus.
          </p>
        </header>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-12">
          <section className="lg:col-span-2 space-y-6">
            <h2 className="text-xs font-bold uppercase tracking-[0.2em] text-white/20 mb-8 flex items-center gap-3">
              Institutional Proposals
              <span className="px-2 py-0.5 rounded-full bg-white/5 text-[10px] font-mono">{proposalCount} Total</span>
            </h2>

            {proposalCount === 0 ? (
              <div className="rounded-3xl border border-white/5 bg-white/[0.01] p-24 text-center">
                <p className="text-white/20 font-medium tracking-wide text-sm">No active proposals in the regional state.</p>
              </div>
            ) : (
              <div className="space-y-6">
                {Array.from({ length: proposalCount }).map((_, i) => (
                  <ProposalCard key={i} id={BigInt(proposalCount - i)} />
                ))}
              </div>
            )}
          </section>

          <aside className="space-y-8">
            <div className="rounded-3xl border border-white/5 bg-white/[0.02] p-8">
              <h2 className="text-lg font-bold mb-6 flex items-center gap-2">
                <Plus className="w-4 h-4 text-violet-400" />
                New Action
              </h2>
              <div className="space-y-6">
                <div>
                  <label className="block text-[10px] font-bold text-white/30 uppercase tracking-widest mb-2">Target Address</label>
                  <input 
                    type="text" 
                    value={targetAddr}
                    onChange={(e) => setTargetAddr(e.target.value)}
                    placeholder="0x..."
                    className="w-full bg-[#0a0a0a] border border-white/10 rounded-xl px-4 py-3 text-sm font-mono focus:outline-none focus:border-violet-500/50 transition-all"
                  />
                </div>
                <div>
                  <label className="block text-[10px] font-bold text-white/30 uppercase tracking-widest mb-2">Action Category</label>
                  <select 
                    value={actionType}
                    onChange={(e) => setActionType(e.target.value)}
                    className="w-full bg-[#0a0a0a] border border-white/10 rounded-xl px-4 py-3 text-sm focus:outline-none focus:border-violet-500/50 transition-all appearance-none cursor-pointer"
                  >
                    <option value="ADD_AUTH">Add Authority</option>
                    <option value="REMOVE_AUTH">Remove Authority</option>
                  </select>
                </div>
                <button 
                  onClick={() => createProposal()}
                  disabled={!targetAddr || isProposing}
                  className="w-full bg-white text-black font-bold py-4 rounded-xl hover:bg-white/90 disabled:opacity-50 disabled:cursor-not-allowed transition-all shadow-xl shadow-white/5"
                >
                  {isProposing ? "Proposing..." : "Submit Proposal"}
                </button>
              </div>
            </div>

            <div className="rounded-3xl border border-white/5 bg-white/[0.01] p-8">
               <h3 className="text-[10px] font-bold uppercase tracking-widest text-white/20 mb-4">Governance Rules</h3>
               <ul className="space-y-4 text-[11px] text-white/40 font-medium leading-relaxed">
                 <li className="flex gap-3"><div className="w-1 h-1 rounded-full bg-violet-500 mt-1.5 shrink-0" /> Quorum: 2f+1 verification of active authorities.</li>
                 <li className="flex gap-3"><div className="w-1 h-1 rounded-full bg-violet-500 mt-1.5 shrink-0" /> Auto-Finalization: Actions execute upon reaching quorum.</li>
               </ul>
            </div>
          </aside>
        </div>
      </div>
    </main>
  );
}

function ProposalCard({ id }: { id: bigint }) {
  const { data: proposal } = useReadContract({
    abi: CONTRACT_ABI,
    address: CONTRACT_ADDRESS as `0x${string}`,
    functionName: "get_proposal",
    args: [id],
  });

  const { send: vote } = useSendTransaction({
    calls: [
      {
        contractAddress: CONTRACT_ADDRESS as `0x${string}`,
        entrypoint: "vote_on_proposal",
        calldata: [id.toString(), "1"], // Support = true
      },
    ],
  });

  const { send: execute } = useSendTransaction({
    calls: [
      {
        contractAddress: CONTRACT_ADDRESS as `0x${string}`,
        entrypoint: "execute_proposal",
        calldata: [id.toString()],
      },
    ],
  });

  if (!proposal) return null;

  const status = getStatusLabel((proposal as any).status);
  const action = getStatusLabel((proposal as any).action_type);
  const votesFor = Number((proposal as any).votes_for);
  const votesAgainst = Number((proposal as any).votes_against);

  return (
    <div className="rounded-3xl border border-white/5 bg-white/[0.015] p-8 hover:bg-white/[0.025] transition-all group">
      <div className="flex justify-between items-start mb-8">
        <div>
          <span className="text-[10px] font-mono text-violet-400 font-bold uppercase tracking-widest block mb-2">Proposal #{id.toString()}</span>
          <h3 className="text-xl font-bold flex items-center gap-3">
             {action}: {num.toHex((proposal as any).target).slice(0, 8)}...{num.toHex((proposal as any).target).slice(-4)}
          </h3>
        </div>
        <span className={`px-3 py-1 rounded-full text-[10px] font-bold tracking-widest uppercase ${
          status === "EXECUTED" ? "bg-blue-500/10 text-blue-400" :
          status === "APPROVED" ? "bg-emerald-500/10 text-emerald-400" :
          "bg-yellow-500/10 text-yellow-400"
        }`}>
          {status}
        </span>
      </div>

      <div className="flex items-center gap-12 mb-8">
         <div className="space-y-1">
            <p className="text-[10px] font-bold text-white/20 uppercase tracking-widest">For</p>
            <p className="text-3xl font-mono font-bold text-emerald-400">{votesFor}</p>
         </div>
         <div className="space-y-1">
            <p className="text-[10px] font-bold text-white/20 uppercase tracking-widest">Against</p>
            <p className="text-3xl font-mono font-bold text-rose-400">{votesAgainst}</p>
         </div>
         <div className="flex-1 pt-4">
            <div className="h-1.5 w-full bg-white/5 rounded-full overflow-hidden">
               <div className="h-full bg-emerald-400 transition-all duration-500" style={{ width: `${(votesFor / (votesFor + votesAgainst + 1)) * 100}%` }} />
            </div>
         </div>
      </div>

      <div className="flex gap-4">
        {status === "PENDING" && (
          <>
            <button 
              onClick={() => vote()}
              className="flex-1 bg-emerald-500/10 hover:bg-emerald-500/20 text-emerald-400 border border-emerald-500/20 py-3 rounded-xl text-xs font-bold transition-all flex items-center justify-center gap-2"
            >
              <CheckCircle2 className="w-4 h-4" /> Cast Support
            </button>
            <button className="flex-1 bg-rose-500/10 hover:bg-rose-500/20 text-rose-400 border border-rose-500/20 py-3 rounded-xl text-xs font-bold transition-all flex items-center justify-center gap-2">
              <XCircle className="w-4 h-4" /> Oppose
            </button>
          </>
        )}
        {status === "APPROVED" && (
           <button 
             onClick={() => execute()}
             className="flex-1 bg-blue-500/10 hover:bg-blue-500/20 text-blue-400 border border-blue-500/20 py-4 rounded-xl text-xs font-bold uppercase tracking-widest transition-all flex items-center justify-center gap-2"
           >
             <Play className="w-4 h-4 fill-current" /> Execute System Action
           </button>
        )}
      </div>
    </div>
  );
}
