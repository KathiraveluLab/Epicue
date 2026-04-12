"use client";

import { useState } from "react";
import Link from "next/link";
import { useAccount, useContract, useSendTransaction } from "@starknet-react/core";
import { CONTRACT_ADDRESS, CONTRACT_ABI } from "@/lib/contract";

export default function DelegatedSubmitPage() {
  const { address } = useAccount();
  const [subjectId, setSubjectId] = useState("");
  const [domain, setDomain] = useState("healthcare");
  const [severity, setSeverity] = useState(1);
  const [consentHash, setConsentHash] = useState("");

  return (
    <main className="min-h-screen bg-[#050505] text-white p-8">
      <div className="max-w-4xl mx-auto">
        <header className="mb-12 border-b border-white/10 pb-8">
          <Link href="/submit" className="text-emerald-400 hover:text-emerald-300 transition-colors mb-4 inline-block font-bold">
            ← Back to Standard Submission
          </Link>
          <h1 className="text-6xl font-black tracking-tighter mb-4">Inclusion Portal</h1>
          <p className="text-2xl text-white/60 font-medium">
            Helping a community member? Use this simplified form to submit data on their behalf. Verified advocates ensure no one is left behind.
          </p>
        </header>

        <section className="bg-white/[0.03] rounded-[40px] p-12 border border-white/5 space-y-12 shadow-2xl">
          <div className="space-y-8">
            {/* Step 1: Identification */}
            <div>
              <h2 className="text-3xl font-bold mb-6 flex items-center gap-4">
                <span className="w-12 h-12 rounded-full bg-white text-black flex items-center justify-center text-xl">1</span>
                Subject ID
              </h2>
              <p className="text-white/40 mb-4 text-lg">Enter the blinded commitment or reference ID for the member you are assisting.</p>
              <input 
                value={subjectId}
                onChange={(e) => setSubjectId(e.target.value)}
                placeholder="Reference Code"
                className="w-full bg-white/5 border-2 border-white/10 rounded-3xl px-8 py-6 text-2xl focus:border-white transition-all outline-none"
              />
            </div>

            {/* Step 2: Consent */}
            <div>
              <h2 className="text-3xl font-bold mb-6 flex items-center gap-4">
                <span className="w-12 h-12 rounded-full bg-white text-black flex items-center justify-center text-xl">2</span>
                Consent Token
              </h2>
              <p className="text-white/40 mb-4 text-lg">Enter the one-time verification code or consent hash provided by the member.</p>
              <input 
                value={consentHash}
                onChange={(e) => setConsentHash(e.target.value)}
                placeholder="Consent Hash"
                className="w-full bg-white/5 border-2 border-white/10 rounded-3xl px-8 py-6 text-2xl focus:border-white transition-all outline-none"
              />
            </div>

            {/* Step 3: Domain */}
            <div>
              <h2 className="text-3xl font-bold mb-6 flex items-center gap-4">
                <span className="w-12 h-12 rounded-full bg-white text-black flex items-center justify-center text-xl">3</span>
                How can we help?
              </h2>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {[
                  { id: "healthcare", label: "Medical Assistance" },
                  { id: "water", label: "Water Access Alert" },
                  { id: "industry", label: "Traceability Audit" },
                  { id: "education", label: "Education Support" }
                ].map((d) => (
                  <button
                    key={d.id}
                    onClick={() => setDomain(d.id)}
                    className={`p-6 rounded-3xl text-left border-2 transition-all ${
                      domain === d.id ? "bg-white text-black border-white" : "bg-white/5 border-white/10 hover:border-white/30"
                    }`}
                  >
                    <div className="text-sm uppercase tracking-widest font-bold mb-1 opacity-60">Domain</div>
                    <div className="text-xl font-bold">{d.label}</div>
                  </button>
                ))}
              </div>
            </div>
          </div>

          <div className="pt-8 border-t border-white/10">
            <button 
              disabled
              className="w-full bg-emerald-500 text-black font-black text-3xl py-8 rounded-[32px] hover:bg-emerald-400 disabled:opacity-50 transition-all shadow-xl shadow-emerald-500/10"
            >
              Submit for Member
            </button>
            <p className="text-center text-white/30 mt-6 text-sm font-medium uppercase tracking-[0.2em]">
                Accountability Pillar: Your Advocate ID will be linked to this submission.
            </p>
          </div>
        </section>

        <footer className="mt-12 text-center text-white/20 text-sm">
            <p>© 2026 EQUISYS Project — Promoting Equity and Sustainability in Digital Societies</p>
        </footer>
      </div>
    </main>
  );
}
