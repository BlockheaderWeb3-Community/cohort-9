import '@rainbow-me/rainbowkit/styles.css';
import {
  getDefaultConfig,
  RainbowKitProvider,
  lightTheme,
} from '@rainbow-me/rainbowkit';
import { WagmiProvider } from 'wagmi';
import { sepolia } from 'wagmi/chains';
import {
  QueryClientProvider,
  QueryClient,
} from '@tanstack/react-query';

import './App.css'
import Header from './components/Header';
import Faucet from './components/Faucet';

// configuration for wagmi and rainbowkit
const config = getDefaultConfig({
  appName: "Davee's TST Faucet",
  projectId: 'd69f9edb23bbe0354a3b186e1bee340c',
  chains: [sepolia],
  ssr: true, // If your dApp uses server side rendering (SSR)
});

const queryClient = new QueryClient();

function App() {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider
          theme={lightTheme({
            accentColor: '#aa3bff',
            accentColorForeground: '#fff',
            borderRadius: 'medium',
          })}
        >
          <Header />
          <Faucet />
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  )
}

export default App
