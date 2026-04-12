"use client";

import { motion } from "framer-motion";
import { cn } from "@/lib/utils";
import { LucideIcon } from "lucide-react";

interface MetricCardProps {
  label: string;
  value: string | number;
  icon: LucideIcon;
  description?: string;
  className?: string;
  trend?: {
    value: number;
    isPositive: boolean;
  };
}

export function MetricCard({
  label,
  value,
  icon: Icon,
  description,
  className,
  trend,
}: MetricCardProps) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      whileHover={{ scale: 1.02 }}
      className={cn(
        "relative overflow-hidden rounded-2xl border border-white/5 bg-white/[0.01] p-6 text-white transition-shadow hover:shadow-lg hover:shadow-violet-500/5",
        "backdrop-blur-md",
        className
      )}
    >
      <div className="absolute right-0 top-0 -mr-4 -mt-4 h-24 w-24 rounded-full bg-violet-500/5 blur-3xl" />
      
      <div className="relative z-10">
        <div className="mb-4 flex items-start justify-between">
          <div className="rounded-xl bg-white/[0.03] p-2.5">
            <Icon className="h-5 w-5 text-violet-400" />
          </div>
          {trend && (
            <div className={cn(
              "text-[10px] font-bold px-2 py-1 rounded-full",
              trend.isPositive ? "text-emerald-400 bg-emerald-400/10" : "text-rose-400 bg-rose-400/10"
            )}>
              {trend.isPositive ? "+" : ""}{trend.value}%
            </div>
          )}
        </div>

        <div>
           <p className="text-xs font-medium text-white/30 uppercase tracking-widest mb-1">{label}</p>
           <h3 className="text-3xl font-bold tracking-tight mb-2">{value}</h3>
           {description && (
             <p className="text-[11px] text-white/40 leading-relaxed max-w-[200px]">{description}</p>
           )}
        </div>
      </div>
    </motion.div>
  );
}
