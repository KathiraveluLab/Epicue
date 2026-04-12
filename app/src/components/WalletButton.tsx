"use client";

import { useConnect, useAccount, useDisconnect } from "@starknet-react/core";

export function WalletButton() {
  const { connect, connectors } = useConnect();
  const { address, isConnected } = useAccount();
  const { disconnect } = useDisconnect();

  if (isConnected && address) {
    return (
      <div className="flex items-center gap-3">
        <span className="text-sm text-emerald-400 font-mono">
          {address.slice(0, 8)}…{address.slice(-6)}
        </span>
        <button
          onClick={() => disconnect()}
          className="px-4 py-2 text-sm rounded-lg border border-white/20 text-white/70 hover:border-white/40 hover:text-white transition-all duration-200"
        >
          Disconnect
        </button>
      </div>
    );
  }

  return (
    <div className="flex gap-2">
      {connectors.map((connector) => (
        <button
          key={connector.id}
          onClick={() => connect({ connector })}
          className="px-4 py-2 text-sm rounded-lg bg-gradient-to-r from-violet-600 to-indigo-600 text-white font-medium hover:from-violet-500 hover:to-indigo-500 transition-all duration-200 shadow-lg shadow-violet-900/30"
        >
          {connector.name}
        </button>
      ))}
    </div>
  );
}
