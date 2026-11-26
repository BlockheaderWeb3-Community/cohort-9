import React from 'react'
import { useReadContract } from 'wagmi'
import { formatEther } from 'viem'
import { openriverAbi, openriverAddress } from '../contracts';

const Card = ({ tokenId, showOnlyListed }: { tokenId: bigint; showOnlyListed?: boolean }) => {
  const { data: onchainNFT } = useReadContract({
    abi: openriverAbi,
    address: openriverAddress,
    functionName: 'tokenURI',
    args: [tokenId],
  });

  const normalizedImageSrc = React.useMemo(() => {
    if (typeof onchainNFT !== 'string' || !onchainNFT) {
      return null;
    }
    if (onchainNFT.startsWith('ipfs://')) {
      return `https://ipfs.io/ipfs/${onchainNFT.replace('ipfs://', '')}`;
    }
    return onchainNFT;
  }, [onchainNFT]);

  // wagmi returns the marketplace struct as a typed object with named fields
  const { data: marketData } = useReadContract({
    abi: openriverAbi,
    address: openriverAddress,
    functionName: 'marketplace',
    args: [tokenId],
  });

  // Debug: log what we're getting
  React.useEffect(() => {
    console.log(`Token ${tokenId.toString()} marketplace data:`, marketData);
  }, [marketData, tokenId]);

  // Handle the data - it could be an array or an object depending on wagmi version
  const isListed = (() => {
    if (!marketData) return false;
    if (Array.isArray(marketData)) return marketData[0];
    return (marketData as any).listing ?? false;
  })();

  const priceWei = (() => {
    if (!marketData) return BigInt(0);
    if (Array.isArray(marketData)) return marketData[1] as bigint;
    return (marketData as any).price ?? BigInt(0);
  })();
  
  const priceEth = formatEther(priceWei);

  // Hide non-listed NFTs if showOnlyListed is true
  if (showOnlyListed && !isListed) {
    return null;
  }

  return (
    <div className="w-full max-w-[300px] rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
      <div className="flex h-[180px] items-center justify-center overflow-hidden rounded-md bg-slate-100">
        {normalizedImageSrc ? (
          <img
            alt={`NFT #${tokenId}`}
            src={normalizedImageSrc}
            className="h-full w-full object-cover"
          />
        ) : (
          <p className="text-sm text-slate-500">NFT image unavailable</p>
        )}
      </div>
      <div className="flex justify-between py-5">
        <h2 className="text-3xl">#{tokenId.toString()}</h2>
        <h2 className="text-3xl font-bold">
          {isListed ? `${priceEth} ETH` : 'Not listed'}
        </h2>
      </div>
    </div>
  );
};

export default Card;
