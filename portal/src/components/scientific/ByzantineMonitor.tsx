"use client";

import { motion } from "framer-motion";
import { ShieldCheck, ShieldAlert, Cpu } from "lucide-react";
import { cn } from "@/lib/utils";

interface ByzantineMonitorProps {
  authorityCount: number;
  byzantineSignals: number;
  networkStatus: "optimal" | "warning" | "critical";
  className?: string;
}

export function ByzantineMonitor({
  authorityCount,
  byzantineSignals,
  networkStatus,
  className,
}: ByzantineMonitorProps) {
  const statusColors = {
    optimal: "text-emerald-400 border-emerald-400/20 bg-emerald-400/5",
    warning: "text-amber-400 border-amber-400/20 bg-amber-400/5",
    critical: "text-rose-400 border-rose-400/20 bg-rose-400/5",
  };

  return (
    <div className={cn("rounded-2xl border border-white/5 bg-white/[0.01] overflow-hidden backdrop-blur-md", className)}>
      <div className="border-b border-white/5 bg-white/[0.02] px-6 py-4 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="rounded-lg bg-violet-600/10 p-2">
            <Cpu className="h-4 w-4 text-violet-400" />
          </div>
          <span className="text-sm font-bold text-white tracking-widest uppercase">BFT Quorum Health</span>
        </div>
        <div className={cn("px-2 py-0.5 rounded-full border text-[10px] font-bold uppercase", statusColors[networkStatus])}>
           {networkStatus}
        </div>
      </div>

      <div className="p-6">
        <div className="grid grid-cols-2 gap-4">
          <div className="space-y-1">
             <div className="flex items-center gap-2 text-white/40 text-[10px] uppercase font-bold tracking-wider">
               <ShieldCheck className="h-3 w-3" /> Authorities
             </div>
             <p className="text-2xl font-bold text-white tracking-tight">{authorityCount}</p>
          </div>
          <div className="space-y-1">
             <div className="flex items-center gap-2 text-white/40 text-[10px] uppercase font-bold tracking-wider">
               <ShieldAlert className="h-3 w-3" /> Signals
             </div>
             <p className="text-2xl font-bold text-white tracking-tight">{byzantineSignals}</p>
          </div>
        </div>

        <div className="mt-6">
          <div className="flex justify-between text-[10px] text-white/20 uppercase font-bold mb-2">
            <span>Quorum Coverage</span>
            <span>{Math.round((authorityCount / 20) * 100)}%</span>
          </div>
          <div className="h-1.5 w-full bg-white/5 rounded-full overflow-hidden">
             <motion.div
               initial={{ width: 0 }}
               animate={{ width: `${(authorityCount / 20) * 100}%` }}
               transition={{ duration: 1, ease: "easeOut" }}
               className="h-full bg-gradient-to-r from-violet-600 to-indigo-600"
             />
          </div>
          <p className="mt-3 text-[10px] text-white/30 leading-tight">
            Consensus mechanism active on Starknet Sepolia. Monitoring for malicious deviation patterns.
          </p>
        </div>
      </div>
    </div>
  );
}
