import './App.css'
import Home from './Home';
import Swap from './Swap';

import '@rainbow-me/rainbowkit/styles.css';
import {  getDefaultConfig,  RainbowKitProvider,} from '@rainbow-me/rainbowkit';
import { WagmiProvider } from 'wagmi';
import {sepolia,} from 'wagmi/chains';
import {QueryClientProvider,QueryClient,} from "@tanstack/react-query";



// configuration for wagmi and rainbowkit

const config = getDefaultConfig({
  appName: 'Blockchain App',
  projectId: 'd69f9edb23bbe0354a3b186e1bee340c',
  chains: [sepolia],
  ssr: true, // If your dApp uses server side rendering (SSR)
});


function App() {
  
  const queryClient = new QueryClient();

  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={
        queryClient
      }>
        <RainbowKitProvider>
          <Home />
          <Swap />
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  )
}

export default App
