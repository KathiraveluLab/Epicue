"use client";

import { useState } from "react";
import Link from "next/link";
import { motion } from "framer-motion";
import { 
  ShieldCheck, 
  ArrowLeft, 
  Database, 
  Zap, 
  Lock,
  ChevronDown,
  CheckCircle2
} from "lucide-react";
import { useAccount, useContract, useSendTransaction, useReadContract } from "@starknet-react/core";
import { WalletButton } from "@/components/WalletButton";
import { CONTRACT_ABI, CONTRACT_ADDRESS } from "@/lib/contract";
import { shortString } from "starknet";
import { cn } from "@/lib/utils";

const DOMAINS = [
  { value: "healthcare", label: "Healthcare", icon: Database, color: "text-blue-400" },
  { value: "water", label: "Water Quality", icon: ShieldCheck, color: "text-cyan-400" },
  { value: "industry", label: "Industrial", icon: Zap, color: "text-orange-400" },
  { value: "education", label: "Education", icon: Lock, color: "text-indigo-400" },
];

const CATEGORIES_BY_DOMAIN: Record<string, { value: string; label: string }[]> = {
  healthcare: [
    { value: "emergency", label: "Emergency Protocol" },
    { value: "primary_care", label: "Primary Care Audit" },
    { value: "mental_health", label: "Mental Health Survey" },
    { value: "maternity", label: "Maternity Access" },
  ],
  water: [
    { value: "potability", label: "Potability Verification" },
    { value: "contamination", label: "Contamination Signal" },
    { value: "infrastructure", label: "Infrastructure Audit" },
    { value: "supply_issue", label: "Resource Deficiency" },
  ],
  industry: [
    { value: "steel_audit", label: "Steel Mill Efficiency" },
    { value: "carbon_footprint", label: "Carbon Ledger Update" },
    { value: "safety_violation", label: "Industrial Safety Alert" },
    { value: "quality_assurance", label: "Benchmark Deviation" },
  ],
  education: [
    { value: "academic_integrity", label: "Integrity Audit" },
    { value: "student_feedback", label: "Sector Feedback" },
    { value: "inclusion_audit", label: "Inclusion Benchmarking" },
    { value: "resource_access", label: "Academic Equity" },
  ],
};

export default function SubmitPage() {
  const { isConnected } = useAccount();
  const [domain, setDomain] = useState("healthcare");
  const [category, setCategory] = useState("primary_care");
  const [severity, setSeverity] = useState(3);
  const [status, setStatus] = useState<"idle" | "submitting" | "success" | "error">("idle");
  const [txHash, setTxHash] = useState<string | null>(null);

  const { contract } = useContract({ abi: CONTRACT_ABI, address: CONTRACT_ADDRESS });
  const { sendAsync } = useSendTransaction({});

  const { data: domainMeta } = useReadContract({
    abi: CONTRACT_ABI,
    address: CONTRACT_ADDRESS,
    functionName: "get_domain_metadata",
    args: [shortString.encodeShortString(domain)],
  });

  const domainDesc = domainMeta ? shortString.decodeShortString((domainMeta as any)[1]) : "EQUISYS Multi-domain Architecture";

  const handleDomainChange = (newDomain: string) => {
    setDomain(newDomain);
    setCategory(CATEGORIES_BY_DOMAIN[newDomain][0].value);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!contract) return;

    setStatus("submitting");
    try {
      const subjectBlinded = `0x${Date.now().toString(16)}${Math.random().toString(16).slice(2, 10)}`;
      const dataHash = shortString.encodeShortString("epicue_v3_gen");
      const timestamp = Math.floor(Date.now() / 1000);

      const call = contract.populate("submit_epicue_record", [
        {
          subject_id: subjectBlinded,
          domain: shortString.encodeShortString(domain),
          category: shortString.encodeShortString(category),
          severity: severity,
          timestamp: timestamp,
          data_hash: dataHash,
        },
      ]);

      const result = await sendAsync([call]);
      setTxHash(result.transaction_hash);
      setStatus("success");
    } catch (err) {
      console.error(err);
      setStatus("error");
    }
  };

  return (
    <main className="min-h-screen flex flex-col bg-[#050505]">
      {/* Sub-nav */}
      <nav className="flex items-center justify-between px-8 py-5 border-b border-white/5 bg-[#050505]/80 backdrop-blur-xl sticky top-0 z-50">
        <Link href="/" className="flex items-center gap-3 group">
          <div className="w-8 h-8 rounded-lg bg-white/5 border border-white/10 flex items-center justify-center group-hover:bg-white/10 transition-all">
            <ArrowLeft className="w-4 h-4 text-white" />
          </div>
          <span className="font-bold text-white tracking-tight">Scientific Protocol Submission</span>
        </Link>
        <WalletButton />
      </nav>

      <div className="flex-1 flex items-center justify-center px-8 py-16">
        <div className="w-full max-w-xl">
          <header className="mb-10 text-center">
            <h1 className="text-3xl font-bold text-white mb-2 tracking-tight">Report Scientific Dataset</h1>
            <p className="text-white/40 text-sm leading-relaxed max-w-sm mx-auto">
              Secure, inter-institutional data transmission. <br />
              Hardened by STARKs and Byzantine consensus.
            </p>
          </header>

          {!isConnected ? (
            <div className="rounded-3xl border border-white/5 bg-white/[0.01] p-12 text-center backdrop-blur-md">
              <div className="w-16 h-16 rounded-2xl bg-violet-600/10 flex items-center justify-center mx-auto mb-6">
                <Lock className="w-8 h-8 text-violet-400" />
              </div>
              <h2 className="text-xl font-bold text-white mb-2">Wallet Connectivity Required</h2>
              <p className="text-white/30 text-sm mb-8">Access the EQUISYS triad by authenticating your institutional key.</p>
              <WalletButton />
            </div>
          ) : status === "success" ? (
            <motion.div 
               initial={{ opacity: 0, scale: 0.95 }}
               animate={{ opacity: 1, scale: 1 }}
               className="rounded-3xl border border-emerald-500/20 bg-emerald-500/5 p-12 text-center backdrop-blur-md"
            >
              <div className="w-16 h-16 rounded-full bg-emerald-500/10 flex items-center justify-center mx-auto mb-6">
                <CheckCircle2 className="w-8 h-8 text-emerald-400" />
              </div>
              <h2 className="text-2xl font-bold text-white mb-2">Protocol Verified</h2>
              <p className="text-white/40 text-sm mb-8 leading-relaxed">
                Your data has been successfully committed to the <span className="text-white font-bold">{domain}</span> domain. 
                STARK proof generated on L2.
              </p>
              {txHash && (
                <div className="bg-black/40 rounded-xl p-4 mb-8">
                  <p className="text-[10px] font-bold text-white/20 uppercase tracking-widest mb-1">Transaction Hash</p>
                  <p className="font-mono text-[10px] text-emerald-400/80 break-all">{txHash}</p>
                </div>
              )}
              <button
                onClick={() => { setStatus("idle"); setTxHash(null); }}
                className="w-full py-4 rounded-2xl bg-white text-black font-bold hover:bg-white/90 transition-all"
              >
                Submit New Protocol
              </button>
            </motion.div>
          ) : (
            <form onSubmit={handleSubmit} className="space-y-8">
              {/* Domain Selection */}
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                {DOMAINS.map((d) => (
                  <button
                    key={d.value}
                    type="button"
                    onClick={() => handleDomainChange(d.value)}
                    className={cn(
                      "flex flex-col items-center justify-center p-4 rounded-2xl border transition-all group",
                      domain === d.value 
                        ? "border-violet-500/50 bg-violet-500/10 shadow-[0_0_20px_rgba(139,92,246,0.1)]" 
                        : "border-white/5 bg-white/[0.01] hover:border-white/10"
                    )}
                  >
                    <d.icon className={cn("h-6 w-6 mb-3 transition-transform group-hover:scale-110", d.color)} />
                    <span className={cn("text-[10px] font-bold uppercase tracking-widest", domain === d.value ? "text-white" : "text-white/30")}>
                      {d.label.split(' ')[0]}
                    </span>
                  </button>
                ))}
              </div>

              {/* Form Content */}
              <div className="rounded-3xl border border-white/5 bg-white/[0.01] p-8 space-y-8 backdrop-blur-md">
                <div>
                  <label className="block text-[10px] font-bold text-white/20 uppercase tracking-[0.2em] mb-4">
                    Report Specification
                  </label>
                  <div className="relative">
                    <select
                      value={category}
                      onChange={(e) => setCategory(e.target.value)}
                      className="w-full appearance-none rounded-2xl border border-white/5 bg-white/[0.02] text-white px-5 py-4 text-sm font-medium focus:outline-none focus:border-violet-500/50 transition-all cursor-pointer"
                    >
                      {CATEGORIES_BY_DOMAIN[domain].map(({ value, label }) => (
                        <option key={value} value={value} className="bg-[#0f0f1a]">
                          {label}
                        </option>
                      ))}
                    </select>
                    <ChevronDown className="absolute right-5 top-1/2 -translate-y-1/2 w-4 h-4 text-white/20 pointer-events-none" />
                  </div>
                </div>

                <div>
                   <div className="flex justify-between items-center mb-4">
                     <label className="block text-[10px] font-bold text-white/20 uppercase tracking-[0.2em]">
                       Impact Priority
                     </label>
                     <span className="text-xs font-bold text-violet-400 bg-violet-400/10 px-2 py-0.5 rounded">
                        Tier {severity}
                     </span>
                   </div>
                   <input
                     type="range"
                     min={1} max={5} step={1}
                     value={severity}
                     onChange={(e) => setSeverity(Number(e.target.value))}
                     className="w-full h-1.5 bg-white/5 rounded-full appearance-none accent-violet-500 cursor-pointer"
                   />
                   <div className="flex justify-between mt-3">
                     <span className="text-[10px] font-bold text-white/10 uppercase tracking-widest">Standard</span>
                     <span className="text-[10px] font-bold text-white/10 uppercase tracking-widest">Critical</span>
                   </div>
                </div>

                <div className="bg-violet-600/5 border border-violet-500/10 rounded-2xl p-5 flex gap-4 items-start">
                  <ShieldCheck className="w-5 h-5 text-violet-400 shrink-0 mt-0.5" />
                  <p className="text-[11px] text-white/40 leading-relaxed font-medium">
                    <span className="text-white">Privacy Enforcement:</span> Blinded subject commitments are generated client-side. No identifiable markers ever touch the Starknet L2 sequencer.
                  </p>
                </div>
              </div>

              {status === "error" && (
                <div className="p-4 rounded-2xl border border-rose-500/20 bg-rose-500/5 text-rose-400 text-xs text-center font-bold uppercase tracking-widest">
                  Transmission Failed · Consensus Conflict
                </div>
              )}

              <button
                type="submit"
                disabled={status === "submitting"}
                className="w-full py-5 rounded-2xl bg-white text-black font-bold hover:bg-white/90 transition-all disabled:opacity-50 disabled:cursor-not-allowed shadow-[0_0_30px_rgba(255,255,255,0.05)]"
              >
                {status === "submitting" ? (
                  <span className="flex items-center justify-center gap-2">
                    <div className="w-4 h-4 border-2 border-black/20 border-t-black rounded-full animate-spin" />
                    Committing Proof…
                  </span>
                ) : "Broadcast Protocol"}
              </button>
            </form>
          )}
        </div>
      </div>

      <footer className="px-8 py-12 border-t border-white/5 text-center">
        <p className="text-[11px] font-bold text-white/20 uppercase tracking-[0.2em]">
          EQUISYS Protocol Interface · Secure Interinstitutional Bridge
        </p>
      </footer>
    </main>
  );
}
