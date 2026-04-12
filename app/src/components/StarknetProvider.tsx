"use client";

import { sepolia } from "@starknet-react/chains";
import { StarknetConfig, publicProvider, argent, braavos } from "@starknet-react/core";

const connectors = [argent(), braavos()];

export function StarknetProvider({ children }: { children: React.ReactNode }) {
  return (
    <StarknetConfig
      chains={[sepolia]}
      provider={publicProvider()}
      connectors={connectors}
    >
      {children}
    </StarknetConfig>
  );
}
