import ReactDOM from 'react-dom/client'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import App from './App'
import './index.css'
import { StarknetConfig, publicProvider, argent, braavos } from '@starknet-react/core'
import { sepolia } from '@starknet-react/chains'

const queryClient = new QueryClient()
const connectors = [argent(), braavos()]

ReactDOM.createRoot(document.getElementById('root')!).render(
  <QueryClientProvider client={queryClient}>
    <StarknetConfig
      chains={[sepolia]}
      provider={publicProvider()}
      connectors={connectors}
    >
      <App />
    </StarknetConfig>
  </QueryClientProvider>
)
