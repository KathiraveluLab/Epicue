import ReactDOM from 'react-dom/client'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import App from './App'
import './index.css'
import { StarknetConfig, jsonRpcProvider, argent, braavos } from '@starknet-react/core'
import { sepolia, devnet } from '@starknet-react/chains'

const queryClient = new QueryClient()
const connectors = [argent(), braavos()]

const localDevnet = {
  ...devnet,
  id: BigInt("0x6465766e6574"), // Unique ID for 'devnet' to avoid conflict with Sepolia
};

const provider = jsonRpcProvider({
  rpc: (chain) => {
    if (chain.id === localDevnet.id) {
      return { nodeUrl: 'http://localhost:5050' }
    }
    return { nodeUrl: 'https://starknet-sepolia.public.blastapi.io' }
  }
})

ReactDOM.createRoot(document.getElementById('root')!).render(
  <QueryClientProvider client={queryClient}>
    <StarknetConfig
      chains={[localDevnet, sepolia]}
      provider={provider}
      connectors={connectors}
    >
      <App />
    </StarknetConfig>
  </QueryClientProvider>
)
