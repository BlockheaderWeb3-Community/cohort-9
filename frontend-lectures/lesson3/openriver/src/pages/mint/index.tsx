import type { NextPage } from 'next';
import Head from 'next/head';
import React, { useState, useEffect } from 'react';
import { useWriteContract, useWaitForTransactionReceipt, useAccount } from 'wagmi';
import { useRouter } from 'next/router';
import { openriverAbi, openriverAddress } from '../../contracts';

const SAMPLE_PRESETS = [
  {
    name: 'Cyberpunk Image',
    uri: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&w=600&q=80',
  },
  {
    name: 'Abstract Fluid',
    uri: 'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?auto=format&fit=crop&w=600&q=80',
  },
  {
    name: 'Cosmic Nebula',
    uri: 'https://images.unsplash.com/photo-1634017839464-5c339ebe3cb4?auto=format&fit=crop&w=600&q=80',
  },
];

const MintPage: NextPage = () => {
  const router = useRouter();
  const { isConnected } = useAccount();

  const [tokenURI, setTokenURI] = useState(SAMPLE_PRESETS[0].uri);
  const [royalty, setRoyalty] = useState<number>(5);

  const { writeContract, data: hash, isPending, error: writeError } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  useEffect(() => {
    if (isSuccess) {
      const timer = setTimeout(() => {
        router.push('/myNFT');
      }, 2000);
      return () => clearTimeout(timer);
    }
  }, [isSuccess, router]);

  const handleMint = () => {
    if (!tokenURI) return;
    writeContract({
      abi: openriverAbi,
      address: openriverAddress,
      functionName: 'newItem',
      args: [tokenURI, BigInt(royalty)],
    });
  };

  return (
    <>
      <Head>
        <title>Mint NFT | OpenRiver</title>
      </Head>

      <div className="max-w-xl mx-auto space-y-6">
        <div className="text-center space-y-1">
          <h1 className="text-2xl font-bold text-white">Create New NFT</h1>
          <p className="text-xs text-slate-400">Fill in details below to mint your unique NFT on smart contract</p>
        </div>

        <div className="simple-card p-6 space-y-4">
          <div>
            <label className="block text-xs font-semibold text-slate-300 mb-1">
              Image URL / Metadata Link
            </label>
            <input
              type="text"
              placeholder="https://..."
              value={tokenURI}
              onChange={(e) => setTokenURI(e.target.value)}
              className="simple-input w-full px-3 py-2 rounded text-xs mb-2"
            />

            <div className="space-y-1">
              <span className="text-xs text-slate-400">Quick Presets:</span>
              <div className="flex flex-wrap gap-2">
                {SAMPLE_PRESETS.map((preset, idx) => (
                  <button
                    key={idx}
                    type="button"
                    onClick={() => setTokenURI(preset.uri)}
                    className={`px-2 py-1 rounded text-xs transition ${
                      tokenURI === preset.uri
                        ? 'bg-sky-600 text-white'
                        : 'bg-slate-800 text-slate-300 hover:text-white'
                    }`}
                  >
                    {preset.name}
                  </button>
                ))}
              </div>
            </div>
          </div>

          <div>
            <div className="flex justify-between items-center mb-1">
              <label className="text-xs font-semibold text-slate-300">
                Creator Royalty Fee (%)
              </label>
              <span className="text-xs font-bold text-amber-400">{royalty}%</span>
            </div>
            <input
              type="range"
              min="0"
              max="50"
              value={royalty}
              onChange={(e) => setRoyalty(Number(e.target.value))}
              className="w-full"
            />
            <p className="text-xs text-slate-400 mt-1">
              You will earn {royalty}% on secondary sales of this NFT.
            </p>
          </div>

          <div className="p-3 bg-slate-900 rounded border border-slate-800 space-y-2">
            <span className="text-xs text-slate-400 font-semibold">Preview:</span>
            <div className="aspect-square w-32 rounded overflow-hidden bg-slate-800 mx-auto">
              {tokenURI ? (
                <img src={tokenURI} alt="Preview" className="w-full h-full object-cover" />
              ) : (
                <div className="w-full h-full flex items-center justify-center text-xs text-slate-500">
                  No Image
                </div>
              )}
            </div>
          </div>

          {writeError && (
            <div className="p-3 bg-red-950 border border-red-800 text-red-300 text-xs rounded">
              Error: {writeError.message.slice(0, 100)}...
            </div>
          )}

          {isSuccess && (
            <div className="p-3 bg-green-950 border border-green-800 text-green-300 text-xs rounded font-semibold">
              🎉 Success! NFT Minted. Redirecting to My NFTs...
            </div>
          )}

          <button
            onClick={handleMint}
            disabled={!isConnected || isPending || isConfirming || !tokenURI}
            className="w-full btn-primary py-3 text-sm font-semibold"
          >
            {isPending || isConfirming
              ? 'Minting NFT...'
              : !isConnected
              ? 'Connect Wallet to Mint'
              : 'Mint NFT'}
          </button>
        </div>
      </div>
    </>
  );
};

export default MintPage;