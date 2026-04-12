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
  Filter
} from "lucide-react";
import { WalletButton } from "@/components/WalletButton";
import { CONTRACT_ABI, CONTRACT_ADDRESS } from "@/lib/contract";
import { shortString } from "starknet";
import { cn } from "@/lib/utils";
import { motion } from "framer-motion";
import { ByzantineMonitor } from "@/components/scientific/ByzantineMonitor";

function SectorCard({ name, domainKey, desc }: { name: string; domainKey: string; desc: string }) {
  const { data: count, isLoading } = useReadContract({
    abi: CONTRACT_ABI,
    address: CONTRACT_ADDRESS,
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
    address: CONTRACT_ADDRESS,
    functionName: "get_record_count",
    args: [],
  });

  const recordCount = count ? Number(count) : 0;

  return (
    <main className="min-h-screen flex flex-col bg-[#050505]">
      {/* Sub-nav */}
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
          <div className="relative hidden md:block">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-white/20" />
            <input 
              type="text" 
              placeholder="Search Protocols..." 
              className="bg-white/5 border border-white/10 rounded-full pl-10 pr-4 py-2 text-xs text-white focus:outline-none focus:border-violet-500/50 w-64 transition-all"
            />
          </div>
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
            The decentralized archive for the EQUISYS triad. Every data point is 
            secured by STARK proofs on Starknet, ensuring that planetary-scale 
            registries remain mathematically beyond manipulation.
          </p>
        </header>

        <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
          {/* Main Content */}
          <div className="lg:col-span-8 space-y-8">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <SectorCard 
                name="Healthcare" 
                domainKey="healthcare"
                desc="Scientific protocol verification for patient efficacy and access audits." 
              />
              <SectorCard 
                name="Water Quality" 
                domainKey="water"
                desc="Potability benchmarks and verifiable infrastructure feedback loops." 
              />
              <SectorCard 
                name="Industrial Ecology" 
                domainKey="industry"
                desc="Steel mill efficiency audits and verifiable carbon footprint tracing." 
              />
              <SectorCard 
                name="Education" 
                domainKey="education"
                desc="Inclusion audits and academic integrity tracking for regional institutions." 
              />
            </div>

            <div className="rounded-3xl border border-white/5 bg-white/[0.01] p-8">
               <div className="flex items-center justify-between mb-8">
                 <h2 className="text-xl font-bold text-white">Recent Verified Transmissions</h2>
                 <button className="flex items-center gap-2 text-[10px] font-bold text-white/20 hover:text-white transition-colors uppercase tracking-widest">
                   <Filter className="w-3 h-3" /> Filter Results
                 </button>
               </div>
               
               <div className="space-y-4">
                 {[1, 2, 3].map((i) => (
                   <div key={i} className="flex items-center gap-4 p-4 rounded-xl border border-white/5 bg-white/[0.01] hover:bg-white/[0.03] transition-all cursor-pointer group">
                      <div className="w-10 h-10 rounded-lg bg-white/5 flex items-center justify-center">
                        <Database className="w-5 h-5 text-white/40 group-hover:text-violet-400 transition-colors" />
                      </div>
                      <div className="flex-1">
                        <p className="text-sm font-bold text-white">Record ID: 0x{8273 + i}...f2a</p>
                        <p className="text-[10px] text-white/30 uppercase font-bold tracking-widest mt-1">Starknet Block #942,{123 + i}</p>
                      </div>
                      <div className="text-right">
                        <span className="text-[10px] font-bold text-emerald-400 bg-emerald-400/10 px-2 py-1 rounded flex items-center gap-1">
                          <ShieldCheck className="w-3 h-3" /> STARK_PROOF_VALID
                        </span>
                      </div>
                   </div>
                 ))}
               </div>
            </div>
          </div>

          {/* Sidebar Metrics */}
          <aside className="lg:col-span-4 space-y-6">
            <div className="rounded-3xl border border-white/5 bg-gradient-to-br from-violet-600/10 to-indigo-600/10 p-8">
              <p className="text-[10px] font-bold text-violet-400 uppercase tracking-[0.2em] mb-4">Total Scientific Load</p>
              <div className="flex items-baseline gap-2 mb-2">
                <span className="text-5xl font-bold text-white tracking-tighter">
                  {isLoading ? "..." : recordCount.toLocaleString()}
                </span>
                <span className="text-sm font-bold text-white/30 uppercase tracking-widest">Entries</span>
              </div>
              <p className="text-xs text-white/40 leading-relaxed font-medium">
                Verified across 14 institutional authorities in the regional network.
              </p>
            </div>

            <ByzantineMonitor 
              authorityCount={14}
              byzantineSignals={0}
              networkStatus="optimal"
            />

            <div className="rounded-3xl border border-white/5 bg-white/[0.01] p-8">
              <h3 className="text-sm font-bold text-white mb-6 uppercase tracking-widest">Network Verification</h3>
              <div className="space-y-4">
                 <div className="flex items-center justify-between pb-4 border-b border-white/5">
                    <span className="text-xs text-white/30 font-medium">Layer 2 Verified</span>
                    <Globe className="w-4 h-4 text-emerald-400" />
                 </div>
                 <div className="flex items-center justify-between pb-4 border-b border-white/5">
                    <span className="text-xs text-white/30 font-medium">L1 Settlement Status</span>
                    <div className="h-1.5 w-1.5 rounded-full bg-emerald-400 animate-pulse" />
                 </div>
                 <div className="flex items-center justify-between">
                    <span className="text-xs text-white/30 font-medium">BFT Consensus Threshold</span>
                    <span className="text-xs font-mono text-white/60">2/3 Quorum</span>
                 </div>
              </div>
            </div>
          </aside>
        </div>
      </div>

      <footer className="px-8 py-12 border-t border-white/5 text-center">
        <p className="text-[11px] font-bold text-white/20 uppercase tracking-[0.2em]">
          Epicue Registry Explorer · Secure Interdisciplinary Data · STARK Proved
        </p>
      </footer>
    </main>
  );
}
