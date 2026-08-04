import React from 'react'
import { useReadContract, useWriteContract, useAccount } from 'wagmi'
import { formatEther } from 'viem'
import { openriverAbi, openriverAddress } from '../contracts'

const Card = ({ tokenId }: { tokenId: bigint }) => {
  const { isConnected } = useAccount()
  const { writeContract } = useWriteContract()

  const { data: tokenURI } = useReadContract({
    abi: openriverAbi,
    address: openriverAddress,
    functionName: 'tokenURI',
    args: [tokenId],
  })

  const { data: marketData } = useReadContract({
    abi: openriverAbi,
    address: openriverAddress,
    functionName: 'marketplace',
    args: [tokenId],
  })

  const imgSrc = React.useMemo(() => {
    if (typeof tokenURI !== 'string' || !tokenURI) return null
    return tokenURI.startsWith('ipfs://')
      ? `https://ipfs.io/ipfs/${tokenURI.replace('ipfs://', '')}`
      : tokenURI
  }, [tokenURI])

  const isListed = marketData?.[0] ?? false
  const price = marketData?.[1] as bigint | undefined
  const priceEth = price ? formatEther(price) : null

  const handleBuy = () => {
    if (!price) return
    writeContract({
      abi: openriverAbi,
      address: openriverAddress,
      functionName: 'purchase',
      args: [tokenId],
      value: price,
    })
  }

  return (
    <div className="group flex flex-col overflow-hidden rounded-2xl border border-white/10 bg-[#13131a] transition-all duration-300 hover:border-violet-500/50 hover:shadow-lg hover:shadow-violet-500/10">
      {/* Image */}
      <div className="relative h-56 w-full overflow-hidden bg-[#1a1a2e]">
        {imgSrc ? (
          <img
            alt={`NFT #${tokenId.toString()}`}
            src={imgSrc}
            className="h-full w-full object-cover transition-transform duration-500 group-hover:scale-105"
          />
        ) : (
          <div className="flex h-full w-full flex-col items-center justify-center gap-2 text-slate-600">
            <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
              <rect x="3" y="3" width="18" height="18" rx="2" />
              <circle cx="8.5" cy="8.5" r="1.5" />
              <path d="M21 15l-5-5L5 21" />
            </svg>
            <p className="text-xs">No image</p>
          </div>
        )}
        {isListed && (
          <div className="absolute top-3 right-3 rounded-full bg-violet-600/90 px-2.5 py-1 text-xs font-semibold text-white backdrop-blur-sm">
            Listed
          </div>
        )}
      </div>

      {/* Info */}
      <div className="flex flex-1 flex-col gap-3 p-4">
        <div className="flex items-center justify-between">
          <span className="text-sm text-slate-400">Token ID</span>
          <span className="font-bold text-white">#{tokenId.toString()}</span>
        </div>

        {isListed && priceEth && (
          <div className="flex items-center justify-between rounded-xl bg-white/5 px-3 py-2">
            <span className="text-xs text-slate-400">Price</span>
            <span className="font-bold text-violet-300">{priceEth} ETH</span>
          </div>
        )}

        {isListed ? (
          <button
            onClick={handleBuy}
            disabled={!isConnected}
            className="mt-auto w-full rounded-xl bg-gradient-to-r from-violet-600 to-indigo-600 py-2.5 text-sm font-semibold text-white transition-opacity hover:opacity-90 disabled:cursor-not-allowed disabled:opacity-40"
          >
            {isConnected ? 'Buy Now' : 'Connect Wallet'}
          </button>
        ) : (
          <div className="mt-auto w-full rounded-xl bg-white/5 py-2.5 text-center text-sm text-slate-500">
            Not Listed
          </div>
        )}
      </div>
    </div>
  )
}

export default Card
