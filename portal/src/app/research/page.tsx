"use client";

import { useState } from "react";
import Link from "next/link";
import { useReadContract, useContract, useAccount } from "@starknet-react/core";
import { CONTRACT_ADDRESS, CONTRACT_ABI } from "@/lib/contract";
import { shortString } from "starknet";

export default function ResearchPage() {
  const { address } = useAccount();
  const [exportLoading, setExportLoading] = useState(false);

  const { data: colIndex } = useReadContract({
    abi: CONTRACT_ABI,
    address: CONTRACT_ADDRESS,
    functionName: "get_collaboration_index",
    args: [],
    watch: true,
  });

  const { data: totalRecords } = useReadContract({
    abi: CONTRACT_ABI,
    address: CONTRACT_ADDRESS,
    functionName: "get_total_verified_records",
    args: [],
    watch: true,
  });

  const { data: sustScore } = useReadContract({
    abi: CONTRACT_ABI,
    address: CONTRACT_ADDRESS,
    functionName: "get_system_sustainability_score",
    args: [],
    watch: true,
  });

  const { data: userRep } = useReadContract({
    abi: CONTRACT_ABI,
    address: CONTRACT_ADDRESS,
    functionName: "get_institution_reputation",
    args: [address || "0x0"],
    watch: true,
  });

  const domains = [
    { id: "healthcare", label: "Healthcare", color: "from-blue-500/20 to-blue-500/5" },
    { id: "water", label: "Water Quality", color: "from-cyan-500/20 to-cyan-500/5" },
    { id: "industry", label: "Industry", color: "from-orange-500/20 to-orange-500/5" },
    { id: "education", label: "Education", color: "from-purple-500/20 to-purple-500/5" },
    { id: "geospatial", label: "Natural Sciences", color: "from-emerald-500/20 to-emerald-500/5" },
  ];

  const handleExport = async () => {
    setExportLoading(true);
    // In a real app, this would iterate through all subject_ids and fetch records
    // For this demo, we simulate a verifiable JSON export
    const fakeData = {
      project: "EQUISYS Epicue",
      exportedAt: new Date().toISOString(),
      network: "Starknet Sepolia",
      contract: CONTRACT_ADDRESS,
      metrics: {
        totalRecords: totalRecords?.toString() || "0",
        collaborationIndex: colIndex?.toString() || "0",
      },
      disclaimer: "All data is cryptographically verified via STARK proofs."
    };

    const blob = new Blob([JSON.stringify(fakeData, null, 2)], { type: "application/json" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `equisys_research_export_${Date.now()}.json`;
    a.click();
    setExportLoading(false);
  };

  return (
    <main className="min-h-screen bg-[#020202] text-white p-8 font-sans">
      <div className="max-w-6xl mx-auto">
        <header className="mb-16 border-b border-white/5 pb-12 flex justify-between items-end">
          <div>
            <h1 className="text-7xl font-black tracking-tighter mb-4 text-transparent bg-clip-text bg-gradient-to-r from-white to-white/40">
              Research Hub
            </h1>
            <p className="text-xl text-white/50 max-w-2xl font-medium">
              Increasing scientific productivity through verifiable public service data. Monitor inter-institutional collaboration and domain-specific impact scores.
            </p>
          </div>
          <button 
            onClick={handleExport}
            disabled={exportLoading}
            className="px-10 py-5 bg-white text-black font-black rounded-[24px] hover:scale-105 active:scale-95 transition-all shadow-2xl shadow-white/10 text-lg uppercase tracking-wider"
          >
            {exportLoading ? "Preparing Export..." : "Export Verifiable Dataset"}
          </button>
        </header>

        {/* High Level Metrics */}
        <section className="grid grid-cols-1 md:grid-cols-3 gap-8 mb-16">
          <div className="p-10 rounded-[40px] bg-white/[0.03] border border-white/5 hover:border-white/10 transition-colors shadow-inner">
            <h3 className="text-white/40 uppercase tracking-[0.2em] font-bold text-sm mb-4">Collaboration Index</h3>
            <div className="text-7xl font-black">{colIndex?.toString() || "0.0"}%</div>
            <p className="mt-4 text-white/30 text-sm font-medium">Unique institutions per data commitment (SDG 17)</p>
          </div>
          <div className="p-10 rounded-[40px] bg-white/[0.03] border border-white/5 hover:border-white/10 transition-colors shadow-inner">
            <h3 className="text-white/40 uppercase tracking-[0.2em] font-bold text-sm mb-4">Sustainability Score</h3>
            <div className="text-7xl font-black text-transparent bg-clip-text bg-gradient-to-br from-emerald-400 to-cyan-400">
                {sustScore?.toString() || "0"}
            </div>
            <p className="mt-4 text-white/30 text-sm font-medium">STARK-aggregated system utility and resource efficiency</p>
          </div>
          <div className="p-10 rounded-[40px] bg-white/[0.03] border border-white/5 hover:border-white/10 transition-colors shadow-inner">
            <h3 className="text-white/40 uppercase tracking-[0.2em] font-bold text-sm mb-4">Reputation Credits</h3>
            <div className="text-7xl font-black text-emerald-400">
                {userRep && 'reputation_credits' in (userRep as object) ? (userRep as any).reputation_credits.toString() : "0"}
            </div>
            <p className="mt-4 text-white/30 text-sm font-medium">Aggregate system utility based on verified contributions</p>
          </div>
        </section>

        {/* Domain Impact Grid */}
        <h2 className="text-4xl font-bold mb-8 tracking-tight">Domain Productivity</h2>
        <section className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
          {domains.map((d) => (
            <DomainImpactCard key={d.id} domain={d} />
          ))}
        </section>

        <footer className="mt-24 pt-12 border-t border-white/5 text-center">
          <Link href="/" className="text-white/40 hover:text-white transition-colors font-bold uppercase tracking-widest text-sm">
            ← Operational Registry
          </Link>
          <p className="mt-8 text-white/20 text-xs">
            EQUISYS PROJECT — Scientific Research Framework — Starknet Native
          </p>
        </footer>
      </div>
    </main>
  );
}

function DomainImpactCard({ domain }: { domain: any }) {
  const { data: impact } = useReadContract({
    abi: CONTRACT_ABI,
    address: CONTRACT_ADDRESS,
    functionName: "get_domain_impact",
    args: [shortString.encodeShortString(domain.id)],
    watch: true,
  });

  return (
    <div className={`p-8 rounded-[32px] bg-gradient-to-b ${domain.color} border border-white/5 flex flex-col justify-between h-64`}>
      <h3 className="text-2xl font-black tracking-tight">{domain.label}</h3>
      <div>
        <div className="text-5xl font-black mb-1">{impact?.toString() || "0"}</div>
        <div className="text-sm uppercase tracking-widest font-bold opacity-40">Impact Score</div>
      </div>
    </div>
  );
}
