import React, { useState, useMemo } from 'react';
import Card from './Card';
import { useNFTs } from '../hooks/useNFTs';
import { useAccount } from 'wagmi';

export const Cards = ({ initialFilter }: { initialFilter?: 'all' | 'listed' | 'my' }) => {
  const { nfts, loading, refresh } = useNFTs();
  const { address } = useAccount();

  const [activeTab, setActiveTab] = useState<'all' | 'listed' | 'my'>(initialFilter || 'all');
  const [searchTerm, setSearchTerm] = useState('');

  const filteredNFTs = useMemo(() => {
    return nfts.filter((nft) => {
      if (activeTab === 'listed' && !nft.isListed) return false;
      if (activeTab === 'my') {
        if (!address) return false;
        if (nft.owner.toLowerCase() !== address.toLowerCase()) return false;
      }

      if (searchTerm.trim() !== '') {
        const query = searchTerm.toLowerCase();
        const matchesName = nft.name.toLowerCase().includes(query);
        const matchesTokenId = nft.tokenId.toString().includes(query);
        const matchesOwner = nft.owner.toLowerCase().includes(query);
        if (!matchesName && !matchesTokenId && !matchesOwner) return false;
      }

      return true;
    });
  }, [nfts, activeTab, searchTerm, address]);

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row justify-between items-center gap-4 simple-card p-4">
        <div className="flex gap-2 bg-slate-900 p-1 rounded-lg border border-slate-800">
          <button
            onClick={() => setActiveTab('all')}
            className={`px-4 py-2 rounded-md text-xs font-semibold transition ${
              activeTab === 'all'
                ? 'bg-sky-600 text-white'
                : 'text-slate-400 hover:text-white'
            }`}
          >
            All NFTs ({nfts.length})
          </button>
          <button
            onClick={() => setActiveTab('listed')}
            className={`px-4 py-2 rounded-md text-xs font-semibold transition ${
              activeTab === 'listed'
                ? 'bg-sky-600 text-white'
                : 'text-slate-400 hover:text-white'
            }`}
          >
            For Sale ({nfts.filter((n) => n.isListed).length})
          </button>
          <button
            onClick={() => setActiveTab('my')}
            className={`px-4 py-2 rounded-md text-xs font-semibold transition ${
              activeTab === 'my'
                ? 'bg-sky-600 text-white'
                : 'text-slate-400 hover:text-white'
            }`}
          >
            My NFTs ({nfts.filter((n) => address && n.owner.toLowerCase() === address.toLowerCase()).length})
          </button>
        </div>

        <div className="flex items-center gap-2 w-full sm:w-auto">
          <input
            type="text"
            placeholder="Search by name or ID..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="simple-input px-3 py-2 rounded-lg text-xs w-full sm:w-64"
          />
          <button
            onClick={refresh}
            title="Reload NFTs"
            className="btn-secondary px-3 py-2 text-xs font-semibold"
          >
            Refresh 🔄
          </button>
        </div>
      </div>

      {loading && (
        <div className="simple-card p-8 text-center text-slate-400 text-sm">
          Loading NFTs... Please wait.
        </div>
      )}

      {!loading && filteredNFTs.length > 0 && (
        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
          {filteredNFTs.map((nft) => (
            <Card key={nft.tokenId.toString()} nft={nft} onRefresh={refresh} />
          ))}
        </div>
      )}

      {!loading && filteredNFTs.length === 0 && (
        <div className="simple-card p-8 text-center space-y-2">
          <h3 className="text-base font-bold text-white">No NFTs Found</h3>
          <p className="text-xs text-slate-400">
            {activeTab === 'my'
              ? address
                ? 'You do not own any NFTs in this store yet. Try minting one!'
                : 'Please connect your wallet to view your owned NFTs.'
              : activeTab === 'listed'
                ? 'There are currently no items put up for sale.'
                : 'No items match your search.'}
          </p>
        </div>
      )}
    </div>
  );
};
