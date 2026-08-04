import { useReadContract } from 'wagmi'
import Card from './Card'
import { openriverAbi, openriverAddress } from '../contracts'

export const Cards = ({ nftNum }: { nftNum?: bigint }) => {
  const { data: tokenIds } = useReadContract({
    abi: openriverAbi,
    address: openriverAddress,
    functionName: 'tokenIds',
  })

  const count = nftNum ?? tokenIds ?? BigInt(0)

  if (Number(count) === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-24 text-center">
        <div className="mb-4 flex h-16 w-16 items-center justify-center rounded-2xl bg-white/5">
          <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" className="text-slate-500">
            <rect x="3" y="3" width="18" height="18" rx="2" />
            <circle cx="8.5" cy="8.5" r="1.5" />
            <path d="M21 15l-5-5L5 21" />
          </svg>
        </div>
        <p className="text-lg font-medium text-slate-400">No NFTs minted yet</p>
        <p className="mt-1 text-sm text-slate-600">Be the first to mint on OpenRiver</p>
      </div>
    )
  }

  return (
    <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4">
      {Array.from({ length: Number(count) }, (_, i) => i + 1).map((i) => (
        <Card key={i} tokenId={BigInt(i)} />
      ))}
    </div>
  )
}
