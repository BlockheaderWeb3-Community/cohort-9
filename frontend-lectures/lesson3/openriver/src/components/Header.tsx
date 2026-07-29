import { ConnectButton } from '@rainbow-me/rainbowkit';
import Link from 'next/link';
import { useRouter } from 'next/router';
import React from 'react';

const Header = () => {
  const router = useRouter();

  const navLinks = [
    { name: 'Home', path: '/' },
    { name: 'Mint NFT', path: '/mint' },
    { name: 'Sell NFT', path: '/list' },
    { name: 'My NFTs', path: '/myNFT' },
  ];

  return (
    <header className="w-full bg-slate-900 border-b border-slate-800 py-4 px-6 sticky top-0 z-50">
      <div className="max-w-6xl mx-auto flex items-center justify-between">
        
        <Link href="/" className="flex items-center gap-2">
          <span className="text-2xl">🌊</span>
          <span className="font-bold text-xl text-white">OpenRiver NFT Store</span>
        </Link>

        <nav className="hidden md:flex items-center gap-2 bg-slate-800 p-1 rounded-lg">
          {navLinks.map((link) => {
            const isActive = router.pathname === link.path;
            return (
              <Link
                key={link.path}
                href={link.path}
                className={`px-4 py-2 rounded-md text-sm font-semibold transition ${
                  isActive
                    ? 'bg-sky-600 text-white'
                    : 'text-slate-300 hover:text-white hover:bg-slate-700'
                }`}
              >
                {link.name}
              </Link>
            );
          })}
        </nav>

        <div>
          <ConnectButton showBalance={false} />
        </div>
      </div>
    </header>
  );
};

export default Header;