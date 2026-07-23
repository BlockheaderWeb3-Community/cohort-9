import React from 'react'
import { useReadContract } from 'wagmi'
import { openriverAbi, openriverAddress } from '../contracts';

const Card = ({ tokenId }: { tokenId: bigint }) => {
  const { data: onchainNFT } = useReadContract({
    abi: openriverAbi,
    address: openriverAddress,
    functionName: 'tokenURI',
    args: [tokenId],
  })

  const normalizedImageSrc = React.useMemo(() => {
    if (typeof onchainNFT !== 'string' || !onchainNFT) {
      return null
    }

    if (onchainNFT.startsWith('ipfs://')) {
      return `https://ipfs.io/ipfs/${onchainNFT.replace('ipfs://', '')}`
    }

    return onchainNFT
  }, [onchainNFT])


         const {data: marketData} = useReadContract({
        abi: openriverAbi,
        address: openriverAddress,
        functionName: "marketplace",
        args: [BigInt(tokenId)]
    })

    console.log(marketData?.[0])

  return (
    <div className="w-full max-w-[300px] rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
      <div className="flex h-[180px] items-center justify-center overflow-hidden rounded-md bg-slate-100">
        {normalizedImageSrc ? (
          <img
            alt="This one na NFT"
            src={normalizedImageSrc}
            className="h-full w-full object-cover"
          />
        ) : (
          <p className="text-sm text-slate-500">NFT image unavailable</p>
        )}
      </div>
      <div className="flex justify-between py-5">
        <h2 className="text-3xl">#29</h2>
        <h2 className="text-3xl font-bold">200 ETH</h2>
      </div>
    </div>
  )
}

export default Card