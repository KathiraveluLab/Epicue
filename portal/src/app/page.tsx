import Link from "next/link";
import { WalletButton } from "@/components/WalletButton";

export default function Home() {
  return (
    <main className="min-h-screen flex flex-col">
      {/* Nav */}
      <nav className="flex items-center justify-between px-8 py-5 border-b border-white/5">
        <div className="flex items-center gap-2">
          <div className="w-7 h-7 rounded-full bg-gradient-to-br from-violet-500 to-indigo-500" />
          <span className="font-semibold text-white tracking-tight">Epicue</span>
        </div>
        <div className="flex items-center gap-6 text-sm text-white/50">
          <Link href="/submit" className="hover:text-white transition-colors">Submit Report</Link>
          <Link href="/registry" className="hover:text-white transition-colors">Registry</Link>
          <WalletButton />
        </div>
      </nav>

      {/* Hero */}
      <div className="flex-1 flex flex-col items-center justify-center px-8 py-24 text-center relative overflow-hidden">
        {/* Background gradient blob */}
        <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
          <div className="w-[800px] h-[500px] rounded-full bg-violet-800/10 blur-[120px]" />
        </div>

        <div className="relative z-10 max-w-3xl">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full border border-violet-500/30 bg-violet-500/10 text-violet-300 text-xs font-medium mb-8">
            <div className="w-1.5 h-1.5 rounded-full bg-violet-400 animate-pulse" />
            EQUISYS Research Project · Starknet Sepolia
          </div>

          <h1 className="text-5xl sm:text-6xl font-bold tracking-tight mb-6 bg-gradient-to-br from-white via-white to-white/50 bg-clip-text text-transparent leading-tight">
            Equity, Privacy &<br />Integrity with Cairo
          </h1>

          <p className="text-lg text-white/50 max-w-2xl mx-auto mb-12 leading-relaxed">
            A FATE-compliant, Starknet-native healthcare data registry. Submit
            anonymous patient reports verified by STARK proofs — no trusted
            third parties, no data exposure.
          </p>

          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Link
              href="/submit"
              className="px-8 py-3.5 rounded-xl bg-gradient-to-r from-violet-600 to-indigo-600 text-white font-semibold hover:from-violet-500 hover:to-indigo-500 transition-all duration-200 shadow-lg shadow-violet-900/40"
            >
              Submit a Report
            </Link>
            <Link
              href="/registry"
              className="px-8 py-3.5 rounded-xl border border-white/10 text-white/70 font-semibold hover:border-white/20 hover:text-white transition-all duration-200"
            >
              View Registry
            </Link>
          </div>
        </div>
      </div>

      {/* FATE Pillars */}
      <section className="px-8 py-16 border-t border-white/5">
        <div className="max-w-5xl mx-auto grid grid-cols-2 sm:grid-cols-4 gap-6">
          {[
            { letter: "F", label: "Fairness", desc: "Low-cost L2 access for all citizens" },
            { letter: "A", label: "Accountability", desc: "STARK-proved execution — no trust required" },
            { letter: "T", label: "Transparency", desc: "Publicly auditable Cairo contracts" },
            { letter: "E", label: "Ethics", desc: "Zero PII on-chain — blinded commitments only" },
          ].map(({ letter, label, desc }) => (
            <div key={letter} className="rounded-2xl border border-white/5 bg-white/[0.02] p-6 hover:border-violet-500/20 transition-colors duration-300">
              <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-violet-600 to-indigo-600 flex items-center justify-center text-white font-bold text-lg mb-4">
                {letter}
              </div>
              <p className="font-semibold text-white mb-1">{label}</p>
              <p className="text-sm text-white/40 leading-relaxed">{desc}</p>
            </div>
          ))}
        </div>
      </section>

      <footer className="text-center py-6 text-xs text-white/20 border-t border-white/5">
        Epicue · EQUISYS Project · EPL v1.0 · Built with Cairo on Starknet
      </footer>
    </main>
  );
}
