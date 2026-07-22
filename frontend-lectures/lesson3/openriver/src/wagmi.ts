import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import {
  sepolia,
} from 'wagmi/chains';

export const config = getDefaultConfig({
  appName: 'RainbowKit App',
  projectId: 'd69f9edb23bbe0354a3b186e1bee340c',
  chains: [
    sepolia
  ],
  ssr: true,
});
