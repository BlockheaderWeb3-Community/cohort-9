import type { ReactNode } from 'react';
import Header from '../components/Header';
import { openriverAddress } from '../contracts';
import { truncateAddress } from '../utils/nft';

type LayoutProps = {
  children: ReactNode;
};

export default function DashboardLayout({ children }: LayoutProps) {
  return (
    <div className="min-h-screen flex flex-col bg-[#07090e] text-slate-100 selection:bg-cyan-500 selection:text-white">
      <Header />

      <main className="flex-1 max-w-7xl w-full mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {children}
      </main>

      <footer className="border-t border-slate-900 bg-slate-950/60 py-8 text-xs text-slate-500">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex flex-col sm:flex-row justify-between items-center gap-4">
          <div className="flex items-center gap-2">
            <span className="font-extrabold text-white font-display">OpenRiver NFT Marketplace</span>
            <span>• Built for EVM Smart Contracts</span>
          </div>

          <div className="flex items-center gap-4">
            <a
              href={`https://sepolia.etherscan.io/address/${openriverAddress}`}
              target="_blank"
              rel="noreferrer"
              className="text-slate-400 hover:text-cyan-400 transition font-mono"
            >
              Contract: {truncateAddress(openriverAddress, 4)} ↗
            </a>
          </div>
        </div>
      </footer>
    </div>
  );
}