"use client";

import { motion } from "framer-motion";
import { History, TrendingDown, Anchor } from "lucide-react";
import { cn } from "@/lib/utils";

interface StabilityGaugeProps {
  currentReputation: number;
  decayFloor: number;
  lastActiveDays: number;
  className?: string;
}

export function StabilityGauge({
  currentReputation,
  decayFloor,
  lastActiveDays,
  className,
}: StabilityGaugeProps) {
  const isDecaying = lastActiveDays > 30;

  return (
    <div className={cn("rounded-2xl border border-white/5 bg-white/[0.01] p-6 backdrop-blur-md", className)}>
      <div className="flex items-center gap-3 mb-6">
        <div className="rounded-lg bg-emerald-600/10 p-2">
          <History className="h-4 w-4 text-emerald-400" />
        </div>
        <span className="text-sm font-bold text-white tracking-widest uppercase">Stability Index</span>
      </div>

      <div className="flex items-end justify-between mb-4">
        <div>
           <p className="text-[10px] text-white/30 uppercase font-bold tracking-wider mb-1">Reputation</p>
           <h3 className="text-4xl font-bold text-white tracking-tighter">{currentReputation}</h3>
        </div>
        <div className="text-right">
           <div className={cn(
             "flex items-center justify-end gap-1 text-[10px] font-bold uppercase",
             isDecaying ? "text-amber-400" : "text-emerald-400"
           )}>
             {isDecaying ? <TrendingDown className="h-3 w-3" /> : null}
             {isDecaying ? "Decaying" : "Stable"}
           </div>
           <p className="text-[10px] text-white/20 mt-1">{lastActiveDays} days since activity</p>
        </div>
      </div>

      <div className="space-y-4">
        <div className="h-2 w-full bg-white/5 rounded-full relative overflow-hidden">
           <motion.div
             initial={{ width: 0 }}
             animate={{ width: `${Math.min((currentReputation / 200) * 100, 100)}%` }}
             transition={{ duration: 1.5, ease: "circOut" }}
             className="h-full bg-gradient-to-r from-emerald-600 to-teal-500"
           />
           {/* Floor marker */}
           <div 
             className="absolute top-0 bottom-0 w-0.5 bg-rose-500/50 z-20"
             style={{ left: `${(decayFloor / 200) * 100}%` }}
           />
        </div>

        <div className="flex items-center justify-between">
           <div className="flex items-center gap-2 text-[10px] text-white/40">
             <Anchor className="h-3 w-3" />
             <span className="font-bold uppercase tracking-wider">Governed Floor: {decayFloor}</span>
           </div>
           <span className="text-[10px] text-white/20 uppercase font-bold tracking-wider">Max Potential: 200</span>
        </div>
      </div>
    </div>
  );
}
