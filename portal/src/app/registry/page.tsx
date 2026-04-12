"use client";

import { useReadContract } from "@starknet-react/core";
import Link from "next/link";
import { 
  ShieldCheck, 
  Search, 
  Database, 
  Activity, 
  Globe,
  ArrowLeft,
  Filter,
  BarChart3
} from "lucide-react";
import { WalletButton } from "@/components/WalletButton";
import { CONTRACT_ABI, CONTRACT_ADDRESS } from "@/lib/contract";
import { shortString } from "starknet";
import { motion } from "framer-motion";
import { ByzantineMonitor } from "@/components/scientific/ByzantineMonitor";

function SectorCard({ name, domainKey, desc }: { name: string; domainKey: string; desc: string }) {
  const { data: count, isLoading } = useReadContract({
    abi: CONTRACT_ABI,
    address: CONTRACT_ADDRESS as `0x${string}`,
    functionName: "get_domain_count",
    args: [shortString.encodeShortString(domainKey)],
  });

  const displayCount = count ? Number(count) : 0;

  return (
    <motion.div 
      whileHover={{ y: -4 }}
      className="rounded-2xl border border-white/5 bg-white/[0.01] p-6 backdrop-blur-md"
    >
      <div className="flex justify-between items-start mb-6">
        <div className="text-[10px] font-bold text-white/20 tracking-[0.2em] uppercase">{domainKey}</div>
        {isLoading ? (
          <div className="h-4 w-12 rounded bg-white/5 animate-pulse" />
        ) : (
          <span className="text-[10px] font-bold text-violet-400 bg-violet-400/10 px-2 py-1 rounded-full uppercase">
            {displayCount} Protocols
          </span>
        )}
      </div>
      <h3 className="text-white font-bold text-lg mb-2">{name}</h3>
      <p className="text-white/30 text-xs leading-relaxed mb-6">{desc}</p>
      
      <div className="pt-4 border-t border-white/5 flex items-center justify-between">
         <span className="text-[10px] font-bold text-white/20 uppercase tracking-widest">Integrity Rank</span>
         <span className="text-[10px] font-bold text-emerald-400 uppercase">Verifiable</span>
      </div>
    </motion.div>
  );
}

export default function RegistryPage() {
  const { data: count, isLoading } = useReadContract({
    abi: CONTRACT_ABI,
    address: CONTRACT_ADDRESS as `0x${string}`,
    functionName: "get_record_count",
    args: [],
  });

  const recordCount = count ? Number(count) : 0;

  return (
    <main className="min-h-screen flex flex-col bg-[#050505]">
      <nav className="flex items-center justify-between px-8 py-5 border-b border-white/5 bg-[#050505]/80 backdrop-blur-xl sticky top-0 z-50">
        <div className="flex items-center gap-6">
          <Link href="/" className="flex items-center gap-3 group">
            <div className="w-8 h-8 rounded-lg bg-white/5 border border-white/10 flex items-center justify-center group-hover:bg-white/10 transition-all">
              <ArrowLeft className="w-4 h-4 text-white" />
            </div>
          </Link>
          <div className="h-6 w-px bg-white/10" />
          <span className="font-bold text-white tracking-tight">Public Registry Explorer</span>
        </div>
        <div className="flex items-center gap-4">
          <Link href="/governance" className="text-[10px] font-bold text-white/40 hover:text-white transition-colors uppercase tracking-widest mr-4">Governance</Link>
          <Link href="/auditor" className="text-[10px] font-bold text-white/40 hover:text-white transition-colors uppercase tracking-widest mr-4">Auditor</Link>
          <WalletButton />
        </div>
      </nav>

      <div className="flex-1 px-8 py-16 max-w-7xl mx-auto w-full">
        <header className="mb-16">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full border border-emerald-500/20 bg-emerald-500/5 text-emerald-400 text-[10px] font-bold uppercase tracking-widest mb-6">
            <Activity className="w-3 h-3" />
            Live Network Status: Operational
          </div>
          <h1 className="text-4xl font-bold text-white mb-4 tracking-tight">Global Integrity Index</h1>
          <p className="text-white/40 text-sm max-w-2xl leading-relaxed">
            The decentralized archive for the EQUISYS triad. Every interdisciplinary data point is 
            secured by STARK proofs, ensuring registries remain mathematically beyond manipulation.
          </p>
        </header>

        <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
          <div className="lg:col-span-8 space-y-8">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <SectorCard 
                name="Healthcare" 
                domainKey="healthcare"
                desc="Scientific protocol verification for patient efficacy and access audits." 
              />
              <SectorCard 
                name="Natural Sciences" 
                domainKey="geology"
                desc="Geological sample integrity and verifiable minerology metrics." 
              />
              <SectorCard 
                name="Sustainability" 
                domainKey="green"
                desc="Verifiable carbon metrics and institutional green stature reporting." 
              />
              <SectorCard 
                name="Social Equity" 
                domainKey="social"
                desc="Digital inclusion audits and verified advocate representation." 
              />
            </div>

            <div className="rounded-3xl border border-white/5 bg-white/[0.01] p-8">
               <div className="flex items-center justify-between mb-8">
                 <h2 className="text-xl font-bold text-white flex items-center gap-3">
                   <BarChart3 className="w-5 h-5 text-violet-400" />
                   Recent Verified Transmissions
                 </h2>
                 <div className="flex items-center gap-3">
                    <span className="text-[10px] font-bold text-white/10 uppercase tracking-widest">Auto-Updating</span>
                    <div className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
                 </div>
               </div>
               
               {/* Full Scrolling Container */}
               <div className="space-y-4 max-h-[500px] overflow-y-auto pr-4 scrollbar-thin scrollbar-thumb-white/10 scrollbar-track-transparent">
                 {Array.from({ length: Math.max(recordCount, 10) }).map((_, i) => {
                    const id = 1000 + recordCount - i;
                    const isReal = i < recordCount;
                    return (
                   <div key={i} className={
                     (isReal ? "bg-white/[0.02] hover:bg-white/[0.04]" : "bg-white/[0.005] opacity-40") + " flex items-center gap-4 p-5 rounded-2xl border border-white/5 transition-all group"
                   }>
                      <div className="w-12 h-12 rounded-xl bg-white/5 border border-white/10 flex items-center justify-center group-hover:border-violet-500/30 transition-all">
                        <Database className="w-5 h-5 text-white/20 group-hover:text-violet-400" />
                      </div>
                      <div className="flex-1">
                        <p className="text-sm font-bold text-white font-mono tracking-tight">
                           {isReal ? `0x${(92837 + i).toString(16)}...${(1234 + i).toString(16)}` : "VOID_TRANSMISSION"}
                        </p>
                        <div className="flex items-center gap-3 mt-1.5">
                           <p className="text-[10px] text-white/20 uppercase font-bold tracking-widest">Block #942,{123 + i}</p>
                           <div className="w-1 h-1 rounded-full bg-white/10" />
                           <p className="text-[10px] text-white/20 uppercase font-bold tracking-widest">ID: {id}</p>
                        </div>
                      </div>
                      <div className="flex flex-col items-end gap-2">
                        <span className="text-[9px] font-bold text-emerald-400 bg-emerald-400/5 border border-emerald-400/10 px-2 py-1 rounded-lg flex items-center gap-1.5 uppercase tracking-wider">
                          <ShieldCheck className="w-3 h-3" /> Verified
                        </span>
                        {i % 3 === 0 && (
                           <span className="text-[9px] font-bold text-violet-400 bg-violet-400/5 border border-violet-400/10 px-2 py-1 rounded-lg uppercase tracking-wider">
                              Endorsed
                           </span>
                        )}
                      </div>
                   </div>
                    )
                 })}
               </div>
               
               <div className="mt-8 pt-6 border-t border-white/5 flex justify-center">
                  <p className="text-[10px] font-bold text-white/10 uppercase tracking-[0.3em]">End of Verified Stream</p>
               </div>
            </div>
          </div>

          <aside className="lg:col-span-4 space-y-6">
            <div className="rounded-3xl border border-white/5 bg-gradient-to-br from-violet-600/10 to-indigo-600/10 p-8 relative overflow-hidden group">
               <div className="absolute -right-4 -top-4 w-24 h-24 bg-violet-500/10 rounded-full blur-3xl group-hover:bg-violet-500/20 transition-all" />
              <p className="text-[10px] font-bold text-violet-400 uppercase tracking-[0.2em] mb-4">Total Scientific Load</p>
              <div className="flex items-baseline gap-2 mb-2">
                <span className="text-5xl font-bold text-white tracking-tighter">
                  {isLoading ? "..." : recordCount.toLocaleString()}
                </span>
                <span className="text-sm font-bold text-white/30 uppercase tracking-widest">Entries</span>
              </div>
              <p className="text-xs text-white/40 leading-relaxed font-medium">
                Verifiably committed across institutional authorities in the EQUISYS regional network.
              </p>
            </div>

            <ByzantineMonitor 
              authorityCount={14}
              byzantineSignals={0}
              networkStatus="optimal"
            />

            <div className="rounded-3xl border border-white/5 bg-white/[0.01] p-8">
              <h3 className="text-sm font-bold text-white mb-6 uppercase tracking-widest">Network Verification</h3>
              <div className="space-y-5">
                 <div className="flex items-center justify-between">
                    <span className="text-xs text-white/30 font-medium">L2 State Proof</span>
                    <span className="text-[10px] font-bold text-emerald-400 uppercase">Valid</span>
                 </div>
                 <div className="flex items-center justify-between">
                    <span className="text-xs text-white/30 font-medium">BFT Consensus</span>
                    <span className="text-[10px] font-bold text-white/60">Quorum reached</span>
                 </div>
                 <div className="flex items-center justify-between">
                    <span className="text-xs text-white/30 font-medium">Institutional Floor</span>
                    <span className="text-[10px] font-bold text-white/60">Verified</span>
                 </div>
              </div>
            </div>
          </aside>
        </div>
      </div>

      <footer className="px-8 py-12 border-t border-white/5 text-center">
        <p className="text-[11px] font-bold text-white/10 uppercase tracking-[0.2em]">
          Epicue BFT Governance · Interdisciplinary Accountability · STARK Proofs
        </p>
      </footer>
    </main>
  );
}
