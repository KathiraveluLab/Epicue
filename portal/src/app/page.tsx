"use client";

import Link from "next/link";
import { motion } from "framer-motion";
import { 
  ShieldCheck, 
  BarChart3, 
  Globe, 
  Activity, 
  Zap, 
  ArrowRight,
  Database,
  Lock
} from "lucide-react";
import { WalletButton } from "@/components/WalletButton";
import { cn } from "@/lib/utils";
import { MetricCard } from "@/components/scientific/MetricCard";
import { ByzantineMonitor } from "@/components/scientific/ByzantineMonitor";
import { StabilityGauge } from "@/components/scientific/StabilityGauge";

export default function Home() {
  return (
    <main className="min-h-screen flex flex-col bg-[#050505] selection:bg-violet-500/30">
      {/* Nav */}
      <nav className="flex items-center justify-between px-8 py-5 border-b border-white/5 sticky top-0 bg-[#050505]/80 backdrop-blur-xl z-50">
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-violet-600 to-indigo-600 flex items-center justify-center">
            <ShieldCheck className="w-5 h-5 text-white" />
          </div>
          <span className="font-bold text-white tracking-tight text-lg">Epicue</span>
        </div>
        <div className="flex items-center gap-8 text-sm font-medium">
          <Link href="/registry" className="text-white/40 hover:text-white transition-colors">Public Registry</Link>
          <Link href="/research" className="text-white/40 hover:text-white transition-colors">Scientific Methodology</Link>
          <Link href="/submit" className="px-5 py-2 rounded-full bg-white/5 border border-white/10 text-white hover:bg-white/10 transition-all">Submit Protocol</Link>
          <WalletButton />
        </div>
      </nav>

      <div className="flex-1">
        {/* Luxury Hero Section */}
        <section className="relative pt-32 pb-24 px-8 overflow-hidden">
          <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[1200px] h-[600px] bg-violet-600/10 blur-[150px] -z-10 rounded-full" />
          
          <div className="max-w-6xl mx-auto text-center">
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full border border-violet-500/20 bg-violet-500/5 text-violet-300 text-[11px] font-bold uppercase tracking-widest mb-8"
            >
              <Zap className="w-3 h-3 animate-pulse" />
              Byzantine Resilience · EQUISYS Framework · Starknet Sepolia
            </motion.div>

            <motion.h1
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.1 }}
              className="text-6xl sm:text-8xl font-bold tracking-tight mb-8 bg-gradient-to-br from-white via-white to-white/40 bg-clip-text text-transparent leading-[1.1]"
            >
              Verifiable Integrity <br />in Untrusted Environments
            </motion.h1>

            <motion.p
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.2 }}
              className="text-lg text-white/40 max-w-3xl mx-auto mb-12 leading-relaxed font-medium"
            >
              Building the decentralized registry for the interdisciplinary sciences. 
              Proven by STARKs, governed by BFT consensus, and hardened against 
              Byzantine actors in global internet environments.
            </motion.p>

            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ delay: 0.3 }}
              className="flex items-center justify-center gap-4"
            >
              <Link
                href="/submit"
                className="group px-10 py-4 rounded-full bg-white text-black font-bold hover:bg-white/90 transition-all flex items-center gap-2"
              >
                Launch Protocol
                <ArrowRight className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
              </Link>
              <Link
                href="/registry"
                className="px-10 py-4 rounded-full border border-white/10 text-white font-bold hover:bg-white/5 transition-all"
              >
                Explorer Dashboard
              </Link>
            </motion.div>
          </div>
        </section>

        {/* Live Metrics Dashboard */}
        <section className="px-8 pb-32 max-w-7xl mx-auto">
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
            <div className="lg:col-span-8 grid grid-cols-1 md:grid-cols-2 gap-6">
              <MetricCard 
                label="Digital Reach Index (DRI)"
                value="0.87"
                icon={Globe}
                description="Social equity score across registered sectors. Goal: 0.95 (SDG 10)."
                trend={{ value: 4.2, isPositive: true }}
              />
              <MetricCard 
                label="Sustainability Ledger"
                value="14.2kt"
                icon={Activity}
                description="Proven carbon traceability in Industrial Steel Mill audits (SDG 12)."
                trend={{ value: 2.1, isPositive: true }}
              />
              <MetricCard 
                label="Proven Integrity"
                value="99.9%"
                icon={BarChart3}
                description="Ratio of STARK-verified records vs submitted attempts."
              />
              <MetricCard 
                label="Accountability Score"
                value="A+"
                icon={Lock}
                description="Real-time FATE compliance rating of the EQUISYS triad."
              />
            </div>
            
            <div className="lg:col-span-4 flex flex-col gap-6">
              <ByzantineMonitor 
                authorityCount={14}
                byzantineSignals={0}
                networkStatus="optimal"
              />
              <StabilityGauge 
                currentReputation={142}
                decayFloor={40}
                lastActiveDays={12}
              />
            </div>
          </div>
        </section>

        {/* Technical Sectors */}
        <section className="bg-white/[0.02] border-y border-white/5 py-32 px-8">
          <div className="max-w-6xl mx-auto text-center mb-20">
            <h2 className="text-4xl font-bold text-white mb-4">Multidisciplinary Foundations</h2>
            <p className="text-white/30 font-medium">Verified data streams across the inter-institutional triad.</p>
          </div>
          
          <div className="max-w-7xl mx-auto grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
            {[
              { title: "Healthcare", icon: Database, color: "text-blue-400", desc: "Patient efficacy & access tracking." },
              { title: "Water Science", icon: ShieldCheck, color: "text-cyan-400", desc: "Potability & infrastructure feedback." },
              { title: "Steel Mills", icon: Activity, color: "text-orange-400", desc: "Carbon traceability & audit reports." },
              { title: "Education", icon: Globe, color: "text-indigo-400", desc: "Academic integrity & inclusion audits." },
            ].map((sector) => (
              <div key={sector.title} className="group p-8 rounded-3xl border border-white/5 bg-white/[0.01] hover:bg-white/[0.04] transition-all cursor-default">
                <sector.icon className={cn("h-8 w-8 mb-6 transition-transform group-hover:scale-110", sector.color)} />
                <h3 className="text-xl font-bold text-white mb-2">{sector.title}</h3>
                <p className="text-sm text-white/30 leading-relaxed font-medium">{sector.desc}</p>
              </div>
            ))}
          </div>
        </section>
      </div>

      <footer className="px-8 py-12 border-t border-white/5 text-center">
        <p className="text-[11px] font-bold text-white/20 uppercase tracking-[0.2em]">
          Epicue Framework · EQUISYS Project · Powered by Cairo & Starknet Sepolia
        </p>
      </footer>
    </main>
  );
}
