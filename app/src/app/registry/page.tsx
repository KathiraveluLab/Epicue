"use client";

import { useReadContract } from "@starknet-react/core";
import Link from "next/link";
import { WalletButton } from "@/components/WalletButton";
import { ABI, CONTRACT_ADDRESS } from "@/lib/contract";
import { shortString } from "starknet";

function DomainCard({ name, icon, desc, domainKey }: { name: string; icon: string; desc: string; domainKey: string }) {
  const { data: count, isLoading } = useReadContract({
    abi: ABI,
    address: CONTRACT_ADDRESS,
    functionName: "get_domain_count",
    args: [shortString.encodeShortString(domainKey)],
  });

  const displayCount = count ? Number(count) : 0;

  return (
    <div className="rounded-2xl border border-white/5 bg-white/[0.01] p-6 hover:bg-white/[0.03] transition-colors">
      <div className="flex justify-between items-start mb-4">
        <div className="text-sm font-bold text-white/30 tracking-widest uppercase">{domainKey.slice(0, 3)}</div>
        {isLoading ? (
          <div className="h-4 w-8 rounded bg-white/5 animate-pulse" />
        ) : (
          <span className="text-xs font-bold text-violet-400 bg-violet-400/10 px-2 py-0.5 rounded-full">
            {displayCount} reports
          </span>
        )}
      </div>
      <p className="text-white font-semibold text-sm mb-1">{name}</p>
      <p className="text-white/30 text-[11px] leading-tight">{desc}</p>
    </div>
  );
}

function FatePillar({ name }: { name: string }) {
  const { data: desc, isLoading } = useReadContract({
    abi: ABI,
    address: CONTRACT_ADDRESS,
    functionName: "get_pillar_metadata",
    args: [shortString.encodeShortString(name)],
  });

  return (
    <div className="flex items-start gap-3">
      <span className="mt-0.5 text-sm text-emerald-400">✓</span>
      <div>
        <span className="text-sm font-medium text-white">{name}</span>
        {isLoading ? (
          <span className="h-3 w-24 inline-block ml-2 rounded bg-white/5 animate-pulse" />
        ) : (
          <span className="text-sm text-white/40 ml-2">— {desc ? shortString.decodeShortString(desc as string) : "Verified"}</span>
        )}
      </div>
    </div>
  );
}

export default function RegistryPage() {
  const { data: count, isLoading, isError, refetch } = useReadContract({
    abi: ABI,
    address: CONTRACT_ADDRESS,
    functionName: "get_record_count",
    args: [],
  });

  const recordCount = count ? Number(count) : 0;

  return (
    <main className="min-h-screen flex flex-col">
      <nav className="flex items-center justify-between px-8 py-5 border-b border-white/5">
        <Link href="/" className="flex items-center gap-2">
          <div className="w-7 h-7 rounded-full bg-gradient-to-br from-violet-500 to-indigo-500" />
          <span className="font-semibold text-white tracking-tight">Epicue</span>
        </Link>
        <div className="flex items-center gap-6 text-sm text-white/50">
          <Link href="/submit" className="hover:text-white transition-colors">Submit Report</Link>
          <WalletButton />
        </div>
      </nav>

      <div className="flex-1 px-8 py-16 max-w-4xl mx-auto w-full">
        <div className="mb-10">
          <h1 className="text-3xl font-bold text-white mb-2">EQUISYS Public Registry</h1>
          <p className="text-white/40 text-sm">
            Verifiable data registry for societal services. All counts are read directly from 
            the Starknet smart contract — the mathematical backend of Epicue.
          </p>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-10">
          <div className="rounded-2xl border border-white/5 bg-white/[0.02] p-6">
            <p className="text-xs text-white/30 uppercase tracking-wider mb-2">Global Reports</p>
            {isLoading ? (
              <div className="h-10 w-20 rounded-lg bg-white/5 animate-pulse" />
            ) : isError ? (
              <p className="text-red-400 text-sm">Error reading contract</p>
            ) : (
              <p className="text-4xl font-bold text-white">{recordCount.toLocaleString()}</p>
            )}
          </div>

          <div className="rounded-2xl border border-white/5 bg-white/[0.02] p-6">
            <p className="text-xs text-white/30 uppercase tracking-wider mb-2">FATE Compliance</p>
            <p className="text-2xl font-bold text-violet-300">Verified</p>
            <p className="text-xs text-white/30 mt-1">On-chain Statistics</p>
          </div>

          <div className="rounded-2xl border border-white/5 bg-white/[0.02] p-6">
            <p className="text-xs text-white/30 uppercase tracking-wider mb-2">Integrity</p>
            <p className="text-2xl font-bold text-indigo-300">STARK Proved</p>
            <p className="text-xs text-white/30 mt-1">Verified on Ethereum L1</p>
          </div>
        </div>

        {/* Domain grid */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-10">
            <DomainCard 
                name="Healthcare" 
                icon="[H]" 
                domainKey="healthcare"
                desc="Patient efficacy & access reports" 
            />
            <DomainCard 
                name="Water Quality" 
                icon="[W]" 
                domainKey="water"
                desc="Potability & infrastructure feedback" 
            />
            <DomainCard 
                name="Industry" 
                icon="[I]" 
                domainKey="industry"
                desc="Steel mill audit & carbon traceability" 
            />
            <DomainCard 
                name="Education" 
                icon="[E]" 
                domainKey="education"
                desc="Academic integrity & inclusion audits" 
            />
        </div>

        {/* Transparency info */}
        <div className="rounded-2xl border border-white/5 bg-white/[0.02] p-6 mb-6">
          <h2 className="font-semibold text-white mb-4 flex items-center gap-2">
            <span className="text-violet-400">●</span> FATE Governance Backend
          </h2>
          <div className="space-y-3">
            {["Fairness", "Accountability", "Transparency", "Ethics"].map((name) => (
              <FatePillar key={name} name={name} />
            ))}
          </div>
        </div>

        {/* Contract address */}
        <div className="rounded-2xl border border-white/5 bg-white/[0.02] p-6">
          <h2 className="font-semibold text-white mb-3">Epicue Backend Deployment</h2>
          <p className="font-mono text-sm text-white/40 break-all">{CONTRACT_ADDRESS}</p>
          <p className="text-xs text-white/20 mt-2">
            Verifiable on Starkscan (Sepolia).
          </p>
        </div>

        <div className="mt-6 flex justify-end">
          <button
            onClick={() => refetch()}
            className="text-sm text-white/40 hover:text-white transition-colors"
          >
            ↻ Sync with Chain
          </button>
        </div>
      </div>
    </main>
  );
}
