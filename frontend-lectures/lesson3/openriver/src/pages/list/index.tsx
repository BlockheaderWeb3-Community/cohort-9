import type { NextPage } from 'next';
import Head from 'next/head';
import React, { useState, useEffect } from 'react';
import { useWriteContract, useWaitForTransactionReceipt, useAccount } from 'wagmi';
import { parseEther } from 'viem';
import { useRouter } from 'next/router';
import { openriverAbi, openriverAddress } from '../../contracts';
import { useNFTs } from '../../hooks/useNFTs';

const ListPage: NextPage = () => {
  const router = useRouter();
  const { isConnected } = useAccount();
  const { userNFTs } = useNFTs();

  const [tokenIdInput, setTokenIdInput] = useState<string>('');
  const [priceEth, setPriceEth] = useState<string>('');

  const { writeContract, data: hash, isPending, error: writeError } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const selectedNFT = userNFTs.find((item) => item.tokenId.toString() === tokenIdInput);

  useEffect(() => {
    if (isSuccess) {
      const timer = setTimeout(() => {
        router.push('/');
      }, 2000);
      return () => clearTimeout(timer);
    }
  }, [isSuccess, router]);

  const handleList = () => {
    if (!tokenIdInput || !priceEth || isNaN(Number(priceEth)) || Number(priceEth) <= 0) return;
    try {
      const priceWei = parseEther(priceEth);
      writeContract({
        abi: openriverAbi,
        address: openriverAddress,
        functionName: 'listOnMarketplace',
        args: [BigInt(tokenIdInput), priceWei],
      });
    } catch (e) {
      console.error(e);
    }
  };

  return (
    <>
      <Head>
        <title>Sell NFT | OpenRiver</title>
      </Head>

      <div className="max-w-md mx-auto space-y-6">
        <div className="text-center space-y-1">
          <h1 className="text-2xl font-bold text-white">Sell Your NFT</h1>
          <p className="text-xs text-slate-400">Put your NFT up for sale on the store</p>
        </div>

        <div className="simple-card p-6 space-y-4">
          <div>
            <label className="block text-xs font-semibold text-slate-300 mb-1">
              Select Owned NFT
            </label>
            {userNFTs.length > 0 ? (
              <select
                value={tokenIdInput}
                onChange={(e) => setTokenIdInput(e.target.value)}
                className="simple-input w-full px-3 py-2 rounded text-xs mb-2"
              >
                <option value="">-- Choose from your collection --</option>
                {userNFTs.map((item) => (
                  <option key={item.tokenId.toString()} value={item.tokenId.toString()}>
                    #{item.tokenId.toString()} - {item.name} {item.isListed ? '(Listed)' : ''}
                  </option>
                ))}
              </select>
            ) : (
              <p className="text-xs text-slate-400 mb-2">
                No owned NFTs detected. You can enter Token ID manually below:
              </p>
            )}

            <input
              type="number"
              placeholder="Or enter Token ID manually (e.g. 1)"
              value={tokenIdInput}
              onChange={(e) => setTokenIdInput(e.target.value)}
              className="simple-input w-full px-3 py-2 rounded text-xs"
            />
          </div>

          {selectedNFT && (
            <div className="flex items-center gap-3 p-3 bg-slate-900 rounded border border-slate-800">
              <img src={selectedNFT.imageSrc} alt={selectedNFT.name} className="w-12 h-12 rounded object-cover" />
              <div className="text-xs">
                <p className="font-bold text-white">{selectedNFT.name}</p>
                <p className="text-slate-400">ID: #{selectedNFT.tokenId.toString()}</p>
              </div>
            </div>
          )}

          <div>
            <label className="block text-xs font-semibold text-slate-300 mb-1">
              Price (ETH)
            </label>
            <input
              type="number"
              step="0.001"
              min="0"
              placeholder="e.g. 0.1"
              value={priceEth}
              onChange={(e) => setPriceEth(e.target.value)}
              className="simple-input w-full px-3 py-2 rounded text-xs"
            />
          </div>

          {writeError && (
            <div className="p-3 bg-red-950 border border-red-800 text-red-300 text-xs rounded">
              Error: {writeError.message.slice(0, 100)}...
            </div>
          )}

          {isSuccess && (
            <div className="p-3 bg-green-950 border border-green-800 text-green-300 text-xs rounded font-semibold">
              🎉 Success! NFT listed for sale. Redirecting to home...
            </div>
          )}

          <button
            onClick={handleList}
            disabled={!isConnected || isPending || isConfirming || !tokenIdInput || !priceEth}
            className="w-full btn-primary py-3 text-sm font-semibold"
          >
            {isPending || isConfirming
              ? 'Submitting...'
              : !isConnected
              ? 'Connect Wallet to Sell'
              : 'List NFT For Sale'}
          </button>
        </div>
      </div>
    </>
  );
};

export default ListPage;