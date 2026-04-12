"use client";

import { useState } from "react";
import Link from "next/link";
import { useAccount, useReadContract, useSendTransaction } from "@starknet-react/core";
import { CONTRACT_ADDRESS, CONTRACT_ABI } from "@/lib/contract";
import { ArrowLeft, ShieldAlert, Award, Activity } from "lucide-react";
import { WalletButton } from "@/components/WalletButton";
import { shortString } from "starknet";

export default function AuditorPage() {
  const { address } = useAccount();
  const [targetNode, setTargetNode] = useState("");

  const { data: complianceScore } = useReadContract({
    abi: CONTRACT_ABI,
    address: CONTRACT_ADDRESS as `0x${string}`,
    functionName: "get_compliance_score",
    args: [],
  });

  const { send: claimBounty, isPending: isClaiming } = useSendTransaction({
    calls: [
      {
        contractAddress: CONTRACT_ADDRESS as `0x${string}`,
        entrypoint: "claim_security_bounty",
        calldata: [targetNode],
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
          <span className="font-bold text-white tracking-tight">Security Auditor Dashboard</span>
        </div>
        <WalletButton />
      </nav>

      <div className="max-w-4xl mx-auto p-8 py-16">
        <header className="mb-12">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full border border-rose-500/20 bg-rose-500/5 text-rose-400 text-[10px] font-bold uppercase tracking-widest mb-6">
            <ShieldAlert className="w-3 h-3" />
            Vigilance Mode Active
          </div>
          <h1 className="text-4xl font-bold mb-4 tracking-tighter">Institutional Integrity Monitor</h1>
          <p className="text-white/40 text-sm max-w-xl leading-relaxed">
            The transparency layer for the EQUISYS triad. Auditors can signal Byzantine signals and 
            initiate programmatic slashing of non-compliant nodes.
          </p>
        </header>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-12">
          <div className="p-8 rounded-3xl border border-white/5 bg-white/[0.01]">
            <p className="text-[10px] font-bold text-white/20 uppercase tracking-[0.2em] mb-2">Network Compliance</p>
            <div className="flex items-baseline gap-2">
               <span className="text-5xl font-bold text-emerald-400">{complianceScore ? Number(complianceScore) : "--"}%</span>
            </div>
          </div>
          <div className="p-8 rounded-3xl border border-white/5 bg-gradient-to-br from-rose-500/10 to-orange-500/10">
            <p className="text-[10px] font-bold text-rose-400 uppercase tracking-[0.2em] mb-2">Byzantine Signals</p>
            <div className="flex items-baseline gap-2">
               <span className="text-5xl font-bold text-white">0</span>
               <span className="text-xs font-bold text-white/30 uppercase">Detected</span>
            </div>
          </div>
        </div>

        <section className="p-8 rounded-3xl border border-white/5 bg-white/[0.02]">
          <h2 className="text-xl font-bold mb-6 flex items-center gap-2">
            <Award className="w-5 h-5 text-violet-400" />
            Claim Security Bounty
          </h2>
          <div className="space-y-4">
            <div>
              <label className="block text-[10px] font-bold text-white/30 uppercase tracking-widest mb-2">Target Node (Byzantine)</label>
              <input 
                type="text" 
                value={targetNode}
                onChange={(e) => setTargetNode(e.target.value)}
                placeholder="0x..."
                className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-4 text-sm font-mono focus:outline-none focus:border-rose-500/50 transition-all"
              />
            </div>
            <button 
              onClick={() => claimBounty()}
              disabled={!targetNode || isClaiming}
              className="w-full bg-rose-500 hover:bg-rose-600 disabled:opacity-50 disabled:cursor-not-allowed text-white font-bold py-4 rounded-xl transition-all shadow-lg shadow-rose-500/10"
            >
              {isClaiming ? "Processing Signal..." : "Signal Fraud & Claim Bounty"}
            </button>
          </div>
        </section>

        <footer className="mt-16 pt-8 border-t border-white/5">
           <div className="flex items-center gap-2 text-[10px] font-bold text-white/10 uppercase tracking-widest">
              <Activity className="w-3 h-3" />
              Real-time audit logs connected to Starknet Core
           </div>
        </footer>
      </div>
    </main>
  );
}
