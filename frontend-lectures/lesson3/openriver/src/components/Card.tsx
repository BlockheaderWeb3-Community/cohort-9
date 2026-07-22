import Image from 'next/image'
import React from 'react'
import { useReadContract } from 'wagmi'
import { openriverAbi, openriverAddress } from '../contracts';


const Card = () => {
  const {data: onchainNFT} = useReadContract(
    {
      abi: openriverAbi,
      address: openriverAddress,
      functionName: "tokenURI",
      args: [BigInt(1n)]
    }
  );

  return (
    <div>
      <div className="">
        <Image alt="This one na NFT" width={300} height={100} src={onchainNFT} />
      </div>
      <div className="flex justify-between py-5">
        <h2 className="text-3xl">#29</h2>
        <h2 className="text-3xl font-bold">200 ETH</h2>
      </div>
    </div>
  )
}

export default Card