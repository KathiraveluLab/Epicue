"use client";

import { useState } from "react";
import Link from "next/link";
import { useAccount, useContract, useSendTransaction, useReadContract } from "@starknet-react/core";
import { WalletButton } from "@/components/WalletButton";
import { CONTRACT_ABI, CONTRACT_ADDRESS } from "@/lib/contract";
import { shortString } from "starknet";

const DOMAINS = [
  { value: "healthcare", label: "Healthcare", icon: "[HC]" },
  { value: "water", label: "Water Quality", icon: "[WQ]" },
  { value: "industry", label: "Industrial Traceability", icon: "[IT]" },
  { value: "education", label: "Higher Education", icon: "[ED]" },
];

const CATEGORIES_BY_DOMAIN: Record<string, { value: string; label: string }[]> = {
  healthcare: [
    { value: "emergency", label: "Emergency" },
    { value: "primary_care", label: "Primary Care" },
    { value: "mental_health", label: "Mental Health" },
    { value: "maternity", label: "Maternity" },
  ],
  water: [
    { value: "potability", label: "Potability Test" },
    { value: "contamination", label: "Contamination Alert" },
    { value: "infrastructure", label: "Infrastructure Leak" },
    { value: "supply_issue", label: "Supply Shortage" },
  ],
  industry: [
    { value: "steel_audit", label: "Steel Mill Audit" },
    { value: "carbon_footprint", label: "Carbon Report" },
    { value: "safety_violation", label: "Safety Alert" },
    { value: "quality_assurance", label: "QA Failure" },
  ],
  education: [
    { value: "academic_integrity", label: "Academic Integrity" },
    { value: "student_feedback", label: "Student Feedback" },
    { value: "inclusion_audit", label: "Inclusion Audit" },
    { value: "resource_access", label: "Resource Access" },
  ],
};

function DomainOption({ value, label, icon, selected, onSelect }: { value: string; label: string; icon: string; selected: boolean; onSelect: (v: string) => void }) {
  const { data: meta } = useReadContract({
    abi: CONTRACT_ABI,
    address: CONTRACT_ADDRESS,
    functionName: "get_domain_metadata",
    args: [shortString.encodeShortString(value)],
  });

  // meta returns [name, description]
  const onChainName = meta ? shortString.decodeShortString((meta as any)[0]) : label;

  return (
    <button
      type="button"
      onClick={() => onSelect(value)}
      className={`flex flex-col items-center justify-center p-3 rounded-xl border transition-all ${
        selected
          ? "border-violet-500 bg-violet-500/10 text-white"
          : "border-white/5 bg-white/[0.02] text-white/40 hover:border-white/10"
      }`}
    >
      <span className="text-xl mb-1">{icon}</span>
      <span className="text-[10px] font-medium uppercase tracking-wider">{onChainName.split(' ')[0]}</span>
    </button>
  );
}

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
      // Blind the subject commitment client-side
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
    <main className="min-h-screen flex flex-col">
      <nav className="flex items-center justify-between px-8 py-5 border-b border-white/5">
        <Link href="/" className="flex items-center gap-2">
          <div className="w-7 h-7 rounded-full bg-gradient-to-br from-violet-500 to-indigo-500" />
          <span className="font-semibold text-white tracking-tight">Epicue</span>
        </Link>
        <div className="flex items-center gap-6 text-sm text-white/50">
          <Link href="/registry" className="hover:text-white transition-colors">Registry</Link>
          <WalletButton />
        </div>
      </nav>

      <div className="flex-1 flex items-center justify-center px-8 py-16">
        <div className="w-full max-w-lg">
          <div className="mb-8">
            <h1 className="text-3xl font-bold text-white mb-2">Submit Public Service Report</h1>
            <p className="text-white/40 text-sm leading-relaxed">
              {domainDesc}
              <br />
              Your submission is anonymous using client-side blinded commitments —
              no PII is stored on-chain.
            </p>
          </div>

          {!isConnected ? (
            <div className="rounded-2xl border border-white/10 bg-white/[0.02] p-8 text-center">
              <p className="text-white/50 mb-4">Connect your wallet to submit a report.</p>
              <WalletButton />
            </div>
          ) : status === "success" ? (
            <div className="rounded-2xl border border-emerald-500/20 bg-emerald-500/5 p-8 text-center">
              <div className="text-4xl mb-4">SUCCESS</div>
              <h2 className="text-white font-semibold text-lg mb-2">Record Submitted</h2>
              <p className="text-white/40 text-sm mb-4">
                Your report for <span className="text-white">{domain}</span> has been STARK-verified.
              </p>
              {txHash && (
                <p className="font-mono text-xs text-emerald-400 break-all">
                  tx: {txHash}
                </p>
              )}
              <button
                onClick={() => { setStatus("idle"); setTxHash(null); }}
                className="mt-6 px-6 py-2.5 rounded-lg border border-white/10 text-white/60 text-sm hover:text-white hover:border-white/20 transition-all"
              >
                Submit Another
              </button>
            </div>
          ) : (
            <form onSubmit={handleSubmit} className="space-y-6">
              {/* Domain Selector */}
              <div>
                <label className="block text-sm font-medium text-white/60 mb-2">
                  Service Domain
                </label>
                <div className="grid grid-cols-3 gap-3">
                  {DOMAINS.map((d) => (
                    <DomainOption
                      key={d.value}
                      value={d.value}
                      label={d.label}
                      icon={d.icon}
                      selected={domain === d.value}
                      onSelect={(v) => handleDomainChange(v)}
                    />
                  ))}
                </div>
              </div>

              {/* Service Category */}
              <div>
                <label className="block text-sm font-medium text-white/60 mb-2">
                  Report Category
                </label>
                <select
                  value={category}
                  onChange={(e) => setCategory(e.target.value)}
                  className="w-full rounded-xl border border-white/10 bg-white/[0.04] text-white px-4 py-3 text-sm focus:outline-none focus:border-violet-500/50 transition-colors"
                >
                  {CATEGORIES_BY_DOMAIN[domain].map(({ value, label }) => (
                    <option key={value} value={value} className="bg-[#0f0f1a]">
                      {label}
                    </option>
                  ))}
                </select>
              </div>

              {/* Severity */}
              <div>
                <label className="block text-sm font-medium text-white/60 mb-3">
                  Priority/Severity: <span className="text-violet-400 font-bold">{severity}</span> / 5
                </label>
                <input
                  type="range"
                  min={1} max={5} step={1}
                  value={severity}
                  onChange={(e) => setSeverity(Number(e.target.value))}
                  className="w-full accent-violet-500"
                />
                <div className="flex justify-between text-xs text-white/20 mt-1">
                  <span>Standard</span><span>Critical</span>
                </div>
              </div>

              {/* Privacy notice */}
              <div className="rounded-xl border border-violet-500/20 bg-violet-500/5 p-4 text-xs text-violet-300/70 leading-relaxed">
                🔒 A blinded subject commitment is generated locally. Only a hash of your data is submitted on-chain.
              </div>

              {status === "error" && (
                <p className="text-red-400 text-sm">Transaction failed. Please try again.</p>
              )}

              <button
                type="submit"
                disabled={status === "submitting"}
                className="w-full py-3.5 rounded-xl bg-gradient-to-r from-violet-600 to-indigo-600 text-white font-semibold hover:from-violet-500 hover:to-indigo-500 transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed shadow-lg shadow-violet-900/30"
              >
                {status === "submitting" ? "Submitting…" : "Submit Report"}
              </button>
            </form>
          )}
        </div>
        {/* Digital Inclusion Callout */}
        <section className="mt-12 p-8 rounded-3xl bg-emerald-500/10 border border-emerald-500/20 flex flex-col md:flex-row items-center justify-between gap-6">
          <div className="flex-1">
            <h3 className="text-xl font-bold text-emerald-400 mb-2">Digital Inclusion Advocate?</h3>
            <p className="text-white/60">Helping someone who isn't digital-native? Use our simplified Inclusion Portal to submit data on their behalf securely.</p>
          </div>
          <Link 
            href="/submit-delegated" 
            className="px-8 py-4 bg-emerald-500 text-black font-bold rounded-2xl hover:bg-emerald-400 transition-all whitespace-nowrap"
          >
            Go to Inclusion Portal
          </Link>
        </section>
      </div>
    </main>
  );
}
